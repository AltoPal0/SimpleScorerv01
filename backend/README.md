# Score 2000 backend

Receives the games the players ask for, and notifies them once the game is in the app.

| Route | Who | What |
|---|---|---|
| `POST /requests` | the app | a game asked, with the device token when notifications are on |
| `GET /requests/summary` | admin (`x-admin-key`) | games asked, most asked first |
| `POST /notify` `{"game": "Skyjo"}` | admin (`x-admin-key`) | push to everyone waiting for this game, once |

Requests are stored in the PostgreSQL of SG2 (Cloud SQL `sg2-db`), database `score2000`, table `game_requests` created on start.

## Configuration

| Variable | Value |
|---|---|
| `ADMIN_KEY` | long random string, for the admin routes |
| `APNS_KEY` | content of the `.p8` key (Apple Developer › Keys › Apple Push Notifications service) |
| `APNS_KEY_ID` | ID of that key |
| `APNS_TEAM_ID` | `3CP7Y3H8F6` |
| `INSTANCE_CONNECTION_NAME` | `sg2-platform:europe-west9:sg2-db` |
| `DB_NAME`, `DB_USER` | `score2000` |
| `DB_PASSWORD` | secret `score2000-db-password` |
| `DATABASE_URL` | optional, replaces the 4 above (local runs) |
| `STORE=memory` | optional, to run locally without a database |

## Run the tests

```sh
pip install -r requirements.txt pytest
pytest                                    # memory store
TEST_DATABASE_URL=postgresql://... pytest # memory store and PostgreSQL
```

## Deploy on Cloud Run

Project `sg2-platform`, region `europe-west9`, next to the database.

```sh
gcloud run deploy score2000 --source backend --project sg2-platform --region europe-west9 --allow-unauthenticated \
  --add-cloudsql-instances sg2-platform:europe-west9:sg2-db \
  --set-env-vars INSTANCE_CONNECTION_NAME=sg2-platform:europe-west9:sg2-db,DB_NAME=score2000,DB_USER=score2000,APNS_KEY_ID=XXXXXXXXXX,APNS_TEAM_ID=3CP7Y3H8F6 \
  --set-secrets DB_PASSWORD=score2000-db-password:latest,ADMIN_KEY=score2000-admin-key:latest,APNS_KEY=score2000-apns-key:latest
```

Then put the service URL in `AppConfig.backendURL` of the app.

## Notify the players

```sh
curl -X POST "$URL/notify" -H "x-admin-key: $ADMIN_KEY" -H "content-type: application/json" -d '{"game": "Skyjo"}'
```
