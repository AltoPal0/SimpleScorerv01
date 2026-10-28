"""Score 2000 backend: game requests from the app and push notifications when a game is added.

POST /requests            from the app: a game asked by the players, with the device token
GET  /requests/summary    admin: games asked, most asked first
POST /notify              admin: tell every player who asked for a game that it is in
"""

import os
import time
import unicodedata
from datetime import datetime, timezone
from typing import Protocol

import httpx
import jwt
from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

APNS_HOSTS = {
    "sandbox": "https://api.sandbox.push.apple.com",
    "production": "https://api.push.apple.com",
}


def normalized(game: str) -> str:
    """Same key as the app: case and accents ignored."""
    decomposed = unicodedata.normalize("NFKD", game.casefold().strip())
    return "".join(c for c in decomposed if not unicodedata.combining(c))


# MARK: - Storage


class Store(Protocol):
    def add(self, request: dict) -> None: ...
    def all(self) -> list[dict]: ...
    def pending(self, game_key: str) -> list[tuple[str, dict]]: ...
    def mark_notified(self, ids: list[str]) -> None: ...


class PostgresStore:
    """The PostgreSQL of SG2 (Cloud SQL), in its own database."""

    columns = "id, game, game_key, locale, device_token, apns_environment, bundle_id, created_at, notified_at"

    def __init__(self, url: str) -> None:
        import psycopg

        self.connection = psycopg.connect(url, autocommit=True)
        self.connection.execute(
            """
            CREATE TABLE IF NOT EXISTS game_requests (
                id BIGSERIAL PRIMARY KEY,
                game TEXT NOT NULL,
                game_key TEXT NOT NULL,
                locale TEXT NOT NULL DEFAULT '',
                device_token TEXT NOT NULL DEFAULT '',
                apns_environment TEXT NOT NULL DEFAULT 'production',
                bundle_id TEXT NOT NULL DEFAULT '',
                created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                notified_at TIMESTAMPTZ
            );
            CREATE INDEX IF NOT EXISTS game_requests_game_key ON game_requests (game_key);
            """
        )

    @staticmethod
    def _request(row: tuple) -> dict:
        return {
            "game": row[1],
            "gameKey": row[2],
            "locale": row[3],
            "deviceToken": row[4],
            "apnsEnvironment": row[5],
            "bundleId": row[6],
            "createdAt": row[7],
            "notifiedAt": row[8],
        }

    def add(self, request: dict) -> None:
        self.connection.execute(
            "INSERT INTO game_requests (game, game_key, locale, device_token, apns_environment, bundle_id) VALUES (%s, %s, %s, %s, %s, %s)",
            (request["game"], request["gameKey"], request["locale"], request["deviceToken"], request["apnsEnvironment"], request["bundleId"]),
        )

    def all(self) -> list[dict]:
        rows = self.connection.execute(f"SELECT {self.columns} FROM game_requests").fetchall()
        return [self._request(row) for row in rows]

    def pending(self, game_key: str) -> list[tuple[str, dict]]:
        rows = self.connection.execute(
            f"SELECT {self.columns} FROM game_requests WHERE game_key = %s AND notified_at IS NULL", (game_key,)
        ).fetchall()
        return [(str(row[0]), self._request(row)) for row in rows]

    def mark_notified(self, ids: list[str]) -> None:
        if ids:
            self.connection.execute("UPDATE game_requests SET notified_at = now() WHERE id = ANY(%s)", ([int(i) for i in ids],))


class MemoryStore:
    """For the tests and for running locally without a database."""

    def __init__(self) -> None:
        self.requests: dict[str, dict] = {}

    def add(self, request: dict) -> None:
        self.requests[str(len(self.requests))] = request

    def all(self) -> list[dict]:
        return list(self.requests.values())

    def pending(self, game_key: str) -> list[tuple[str, dict]]:
        return [(i, r) for i, r in self.requests.items() if r["gameKey"] == game_key and not r.get("notifiedAt")]

    def mark_notified(self, ids: list[str]) -> None:
        for doc_id in ids:
            self.requests[doc_id]["notifiedAt"] = datetime.now(timezone.utc)


_store: Store | None = None


def database_url() -> str:
    """DATABASE_URL, or the Cloud SQL socket of Cloud Run with the password from Secret Manager."""
    if url := os.environ.get("DATABASE_URL"):
        return url
    from psycopg.conninfo import make_conninfo

    return make_conninfo(
        host=f"/cloudsql/{os.environ['INSTANCE_CONNECTION_NAME']}",
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
    )


def get_store() -> Store:
    global _store
    if _store is None:
        _store = MemoryStore() if os.environ.get("STORE") == "memory" else PostgresStore(database_url())
    return _store


# MARK: - APNs


class Apns:
    """Token based authentication: the .p8 key of the Apple developer account."""

    def __init__(self, key: str, key_id: str, team_id: str) -> None:
        self.key = key
        self.key_id = key_id
        self.team_id = team_id
        self._token: tuple[str, float] | None = None

    def token(self) -> str:
        # Apple accepts a token for an hour, refreshed every 50 minutes
        if self._token is None or time.time() - self._token[1] > 50 * 60:
            issued = time.time()
            token = jwt.encode(
                {"iss": self.team_id, "iat": int(issued)},
                self.key,
                algorithm="ES256",
                headers={"kid": self.key_id},
            )
            self._token = (token, issued)
        return self._token[0]

    def send(self, client: httpx.Client, device_token: str, environment: str, topic: str, message: str) -> bool:
        response = client.post(
            f"{APNS_HOSTS.get(environment, APNS_HOSTS['production'])}/3/device/{device_token}",
            json={"aps": {"alert": message, "sound": "default"}},
            headers={
                "authorization": f"bearer {self.token()}",
                "apns-topic": topic,
                "apns-push-type": "alert",
            },
        )
        return response.status_code == 200


def get_apns() -> Apns:
    key = os.environ.get("APNS_KEY", "").replace("\\n", "\n")
    if not key:
        raise HTTPException(503, "APNS_KEY is not configured")
    return Apns(key, os.environ["APNS_KEY_ID"], os.environ["APNS_TEAM_ID"])


# MARK: - API

app = FastAPI(title="Score 2000")


def admin(x_admin_key: str = Header(default="")) -> None:
    expected = os.environ.get("ADMIN_KEY")
    if not expected or x_admin_key != expected:
        raise HTTPException(401, "Admin key required")


class GameRequestIn(BaseModel):
    game: str = Field(min_length=1, max_length=60)
    locale: str = Field(default="", max_length=20)
    deviceToken: str = Field(default="", max_length=200, pattern=r"^[0-9a-fA-F]*$")
    apnsEnvironment: str = Field(default="production", pattern=r"^(sandbox|production)$")
    bundleId: str = Field(default="", max_length=100)


@app.get("/")
def health() -> dict:
    return {"ok": True}


@app.post("/requests")
def add_request(request: GameRequestIn, store: Store = Depends(get_store)) -> dict:
    store.add(
        {
            **request.model_dump(),
            "game": request.game.strip(),
            "gameKey": normalized(request.game),
            "createdAt": datetime.now(timezone.utc),
            "notifiedAt": None,
        }
    )
    return {"ok": True}


@app.get("/requests/summary", dependencies=[Depends(admin)])
def summary(store: Store = Depends(get_store)) -> list[dict]:
    games: dict[str, dict] = {}
    for request in store.all():
        game = games.setdefault(request["gameKey"], {"game": request["game"], "requests": 0, "waiting": 0})
        game["requests"] += 1
        if not request.get("notifiedAt") and request.get("deviceToken"):
            game["waiting"] += 1
    return sorted(games.values(), key=lambda game: game["requests"], reverse=True)


class NotifyIn(BaseModel):
    game: str = Field(min_length=1, max_length=60)
    message: str | None = Field(default=None, max_length=200)


@app.post("/notify", dependencies=[Depends(admin)])
def notify(body: NotifyIn, store: Store = Depends(get_store)) -> dict:
    apns = get_apns()
    message = body.message or f"{body.game} is now in Score 2000. Have a great game!"

    sent, failed, notified = 0, 0, []
    with httpx.Client(http2=True, timeout=10) as client:
        for doc_id, request in store.pending(normalized(body.game)):
            if not request.get("deviceToken"):
                # Asked without accepting the notifications: nothing to send, nothing left to do
                notified.append(doc_id)
                continue
            if apns.send(client, request["deviceToken"], request["apnsEnvironment"], request["bundleId"], message):
                sent += 1
                notified.append(doc_id)
            else:
                failed += 1

    store.mark_notified(notified)
    return {"sent": sent, "failed": failed}
