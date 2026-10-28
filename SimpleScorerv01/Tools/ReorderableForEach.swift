//
//  ReorderableForEach.swift
//  SimpleScorerv01
//
//  Created by Dev on 20/1/23.
//  Copyright © 2023 Stephane Giloppe. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct ReorderableForEach<Content: View, Item: Identifiable & Equatable>: View {
    let items: [Item]
    let content: (Item) -> Content
    let moveAction: (IndexSet, Int) -> Void
    
    // Owned by the parent : a drag dropped outside the items never reaches performDrop,
    // the parent resets the state with a DropResetDelegate on its container
    @Binding var draggingItem: Item?
    // A little hack that is needed in order to make view back opaque
    // if the drag and drop hasn't ever changed the position
    // Without this hack the item remains semi-transparent
    @Binding var hasChangedLocation: Bool

    init(
        items: [Item],
        draggingItem: Binding<Item?>,
        hasChangedLocation: Binding<Bool>,
        @ViewBuilder content: @escaping (Item) -> Content,
        moveAction: @escaping (IndexSet, Int) -> Void
    ) {
        self.items = items
        self._draggingItem = draggingItem
        self._hasChangedLocation = hasChangedLocation
        self.content = content
        self.moveAction = moveAction
    }
    
    var body: some View {
        ForEach(items) { item in
            content(item)
                .overlay(
                    (draggingItem == item && hasChangedLocation ? Color.offWhite.opacity(0.8) : Color.clear)
                        .cornerRadius(14)
                        .allowsHitTesting(false)
                )
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 14))
                .onDrag {
                    // A previous drag may have been cancelled without any drop
                    hasChangedLocation = false
                    draggingItem = item
                    return NSItemProvider(object: "\(item.id)" as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: DragRelocateDelegate(
                        item: item,
                        listData: items,
                        current: $draggingItem,
                        hasChangedLocation: $hasChangedLocation
                    ) { from, to in
                        withAnimation {
                            moveAction(from, to)
                        }
                    }
                )
        }
    }
}

struct DragRelocateDelegate<Item: Equatable>: DropDelegate {
    let item: Item
    var listData: [Item]
    @Binding var current: Item?
    @Binding var hasChangedLocation: Bool

    var moveAction: (IndexSet, Int) -> Void

    func dropEntered(info: DropInfo) {
        guard item != current, let current = current else { return }
        guard let from = listData.firstIndex(of: current), let to = listData.firstIndex(of: item) else { return }
        
        hasChangedLocation = true

        if listData[to] != current {
            moveAction(IndexSet(integer: from), to > from ? to + 1 : to)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        hasChangedLocation = false
        current = nil
        return true
    }
}

// Catches the drops between or around the items to end the drag cleanly
struct DropResetDelegate: DropDelegate {
    var reset: () -> Void
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        reset()
        return true
    }
}
