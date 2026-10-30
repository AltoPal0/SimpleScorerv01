//
//  LiveShare.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/30/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import UIKit
import Combine
import MultipeerConnectivity

// The game as sent to the devices watching it
struct LiveGame: Codable {
    var players: [GameSnapshot.SavedPlayer]
    // nil until the game is chosen, "" for the universal entry without name
    var gameName: String?
    var options: GameOptions
}

extension Game {
    var live: LiveGame {
        LiveGame(players: savedPlayers, gameName: rules?.name, options: options)
    }

    // The game received from the device keeping the scores
    func show(_ live: LiveGame) {
        rules = live.gameName.map { GameLibrary.rules(named: $0) }
        options = live.options
        setPlayers(live.players)
    }
}

// A game shown live on the devices nearby : the iPhone keeping the scores streams it, an iPad or another iPhone watches.
// Device to device through Wi-Fi or Bluetooth : no internet, no account, the app on both devices
final class LiveShare: NSObject, ObservableObject {

    static let shared = LiveShare()
    // Up to 15 lowercase letters, digits and hyphens : the same in NSBonjourServices of Info.plist
    static let serviceType = "score2000-live"

    enum Role {
        case none, streaming, watching
    }

    // A game streamed nearby, as seen by the devices looking for one
    struct Stream: Identifiable, Equatable {
        let peer: MCPeerID
        let gameName: String
        var id: MCPeerID { peer }
        var deviceName: String { peer.displayName }
        var label: String { gameName.isEmpty ? deviceName : deviceName + " · " + gameName }
    }

    @Published private(set) var role = Role.none
    // Streaming : how many devices watch
    @Published private(set) var viewerCount = 0
    // Watching : the games streamed nearby, the one followed and whether its scores come in
    @Published private(set) var streams = [Stream]()
    @Published private(set) var followed: Stream?
    @Published private(set) var isConnected = false

    // Watching : the game received, never saved on this device
    let game: Game = {
        let game = Game()
        game.isMirror = true
        return game
    }()

    private let peer = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    // Streaming : the game played on this device
    private weak var streamed: Game?
    private var changes: AnyCancellable?
    private var foreground: AnyCancellable?

    override init() {
        super.init()
        // iOS cuts the connections of an app left : back on screen, they start again
        foreground = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.restart() }
    }

    // MARK: - Streaming

    func startStreaming(_ game: Game) {
        stop()
        streamed = game
        role = .streaming
        startAdvertising()
        // Every change of the game, a few at once when they follow each other (a whole round)
        changes = game.objectWillChange
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.sendGame() }
    }

    private func startAdvertising() {
        let session = newSession()
        let advertiser = MCNearbyServiceAdvertiser(peer: peer,
                                                   discoveryInfo: ["game": streamed?.rules?.displayName ?? ""],
                                                   serviceType: LiveShare.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.session = session
        self.advertiser = advertiser
        viewerCount = 0
    }

    private func sendGame(to peers: [MCPeerID]? = nil) {
        guard role == .streaming, let session = session, let game = streamed else { return }
        let peers = peers ?? session.connectedPeers
        guard !peers.isEmpty, let data = try? JSONEncoder().encode(game.live) else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }

    // MARK: - Watching

    func startWatching() {
        stop()
        role = .watching
        startBrowsing()
        // The device watching is a scoreboard : its screen stays on
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func startBrowsing() {
        session = newSession()
        let browser = MCNearbyServiceBrowser(peer: peer, serviceType: LiveShare.serviceType)
        browser.delegate = self
        browser.startBrowsingPeer()
        self.browser = browser
        streams = []
        isConnected = false
    }

    func follow(_ stream: Stream) {
        followed = stream
        invite(stream.peer)
    }

    // Back to the games streamed nearby
    func unfollow() {
        followed = nil
        startBrowsingAgain()
    }

    private func invite(_ peer: MCPeerID) {
        guard let session = session else { return }
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 15)
    }

    // A connection lost : the games nearby are looked for again, the one followed is joined again once found
    private func startBrowsingAgain() {
        browser?.stopBrowsingPeer()
        session?.disconnect()
        startBrowsing()
    }

    // MARK: - Both

    func stop() {
        changes = nil
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingPeer()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        streamed = nil
        role = .none
        viewerCount = 0
        streams = []
        followed = nil
        isConnected = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func restart() {
        switch role {
        case .streaming:
            advertiser?.stopAdvertisingPeer()
            session?.disconnect()
            startAdvertising()
        case .watching:
            startBrowsingAgain()
        case .none:
            break
        }
    }

    private func newSession() -> MCSession {
        let session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }
}

extension LiveShare: MCNearbyServiceAdvertiserDelegate {
    // Anyone nearby with the app may watch : the scores only, nothing can be changed from there
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            guard advertiser === self.advertiser else {
                invitationHandler(false, nil)
                return
            }
            invitationHandler(true, self.session)
        }
    }
}

extension LiveShare: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            guard browser === self.browser else { return }
            let stream = Stream(peer: peerID, gameName: info?["game"] ?? "")
            self.streams.removeAll { $0.peer == peerID }
            self.streams.append(stream)
            // The device followed is back (its app left and opened again) : joined again
            if let followed = self.followed, !self.isConnected,
               followed.peer == peerID || followed.deviceName == stream.deviceName {
                self.followed = stream
                self.invite(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            guard browser === self.browser else { return }
            self.streams.removeAll { $0.peer == peerID }
        }
    }
}

extension LiveShare: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            guard session === self.session else { return }
            switch self.role {
            case .streaming:
                self.viewerCount = session.connectedPeers.count
                // A new device watching gets the game as it is
                if state == .connected {
                    self.sendGame(to: [peerID])
                }
            case .watching:
                guard peerID == self.followed?.peer else { return }
                self.isConnected = state == .connected
                if state == .notConnected {
                    self.startBrowsingAgain()
                }
            case .none:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let live = try? JSONDecoder().decode(LiveGame.self, from: data) else { return }
        DispatchQueue.main.async {
            guard session === self.session, self.role == .watching else { return }
            self.game.show(live)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
