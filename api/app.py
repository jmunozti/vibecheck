import os
import random

import psycopg2
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app
from pydantic import BaseModel

POSTGRES_HOST = os.environ["POSTGRES_HOST"]
POSTGRES_USER = os.environ["POSTGRES_USER"]
POSTGRES_PASSWORD = os.environ["POSTGRES_PASSWORD"]
POSTGRES_DB = os.environ["POSTGRES_DB"]
OPTION_A = os.environ["OPTION_A"]
OPTION_B = os.environ["OPTION_B"]

app = FastAPI(title="vibecheck API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


class PollRequest(BaseModel):
    choice: str
    user_id: str | None = None


def get_db():
    conn = psycopg2.connect(
        host=POSTGRES_HOST,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
        database=POSTGRES_DB,
    )
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS polls (
            id VARCHAR(255) NOT NULL UNIQUE,
            choice VARCHAR(255) NOT NULL
        );
    """)
    conn.commit()
    cursor.close()
    return conn


@app.get("/")
def api_info():
    return {"service": "vibecheck-api", "options": {"a": OPTION_A, "b": OPTION_B}}


@app.get("/healthz")
def health_check():
    return {"status": "ok"}


@app.post("/poll")
def poll(body: PollRequest):
    if body.choice not in ("a", "b"):
        raise HTTPException(status_code=400, detail="Invalid option. Must be 'a' or 'b'")

    user_id = body.user_id or hex(random.getrandbits(64))[2:-1]

    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO polls (id, choice) VALUES (%s, %s) ON CONFLICT (id) DO UPDATE SET choice = EXCLUDED.choice",
            (user_id, body.choice),
        )
        conn.commit()
        cursor.close()
        return {"success": True, "user_id": user_id, "choice": body.choice}
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


@app.get("/results")
def results():
    conn = get_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT choice, COUNT(id) AS count FROM polls GROUP BY choice")
        rows = cursor.fetchall()
        cursor.close()
        counts = {"a": 0, "b": 0}
        for row in rows:
            if row[0] in counts:
                counts[row[0]] = row[1]
        return counts
    except psycopg2.Error as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()
