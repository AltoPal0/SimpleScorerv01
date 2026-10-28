import os

os.environ["STORE"] = "memory"
os.environ["ADMIN_KEY"] = "secret"

import pytest
from fastapi.testclient import TestClient

import main

client = TestClient(main.app)
ADMIN = {"x-admin-key": "secret"}

# Every test runs on the memory store, and on PostgreSQL when TEST_DATABASE_URL is given
STORES = ["memory"] + (["postgres"] if os.environ.get("TEST_DATABASE_URL") else [])


@pytest.fixture(autouse=True, params=STORES)
def store(request):
    if request.param == "postgres":
        main._store = main.PostgresStore(os.environ["TEST_DATABASE_URL"])
        main._store.connection.execute("TRUNCATE game_requests")
    else:
        main._store = main.MemoryStore()
    yield main._store


def test_normalized_matches_the_app() -> None:
    assert main.normalized("  Mölkky ") == "molkky"
    assert main.normalized("PÉTANQUE") == "petanque"


def test_request_is_stored_and_counted() -> None:
    for token in ["ab12", "", "cd34"]:
        response = client.post("/requests", json={"game": "Skyjo", "deviceToken": token, "apnsEnvironment": "sandbox", "bundleId": "com.StephDev.Score2000"})
        assert response.status_code == 200
    client.post("/requests", json={"game": "skyjo "})
    client.post("/requests", json={"game": "Dixit"})

    summary = client.get("/requests/summary", headers=ADMIN).json()
    assert summary[0] == {"game": "Skyjo", "requests": 4, "waiting": 2}
    assert summary[1]["game"] == "Dixit"


def test_bad_requests_are_refused() -> None:
    assert client.post("/requests", json={"game": ""}).status_code == 422
    assert client.post("/requests", json={"game": "Uno", "deviceToken": "not hex!"}).status_code == 422
    assert client.post("/requests", json={"game": "Uno", "apnsEnvironment": "other"}).status_code == 422


def test_admin_routes_need_the_key() -> None:
    assert client.get("/requests/summary").status_code == 401
    assert client.post("/notify", json={"game": "Skyjo"}).status_code == 401


def test_notify_sends_once_per_device(monkeypatch) -> None:
    client.post("/requests", json={"game": "Skyjo", "deviceToken": "ab12", "apnsEnvironment": "sandbox", "bundleId": "app"})
    client.post("/requests", json={"game": "Skyjo"})
    client.post("/requests", json={"game": "Dixit", "deviceToken": "cd34"})

    sent_to = []

    class FakeApns:
        def send(self, client, device_token, environment, topic, message):
            sent_to.append((device_token, environment, topic, message))
            return True

    monkeypatch.setattr(main, "get_apns", lambda: FakeApns())

    assert client.post("/notify", json={"game": "skyjo"}, headers=ADMIN).json() == {"sent": 1, "failed": 0}
    assert sent_to == [("ab12", "sandbox", "app", "skyjo is now in Score 2000. Have a great game!")]
    # Already told : nothing is sent twice
    assert client.post("/notify", json={"game": "Skyjo"}, headers=ADMIN).json() == {"sent": 0, "failed": 0}
