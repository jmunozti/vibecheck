import logging
import os
from contextlib import contextmanager

import psycopg2
import psycopg2.pool
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("vibecheck-api")

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

# Connection pool (lazy init)
_pool = None


def _get_pool():
    global _pool
    if _pool is None:
        _pool = psycopg2.pool.SimpleConnectionPool(
            minconn=2,
            maxconn=10,
            host=POSTGRES_HOST,
            user=POSTGRES_USER,
            password=POSTGRES_PASSWORD,
            database=POSTGRES_DB,
        )
        # Create table on first connection
        conn = _pool.getconn()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS polls (
                    id SERIAL PRIMARY KEY,
                    choice VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP DEFAULT NOW()
                );
            """)
            conn.commit()
            cursor.close()
            logger.info("Table 'polls' ready")
        finally:
            _pool.putconn(conn)
    return _pool


@contextmanager
def get_db():
    pool = _get_pool()
    conn = pool.getconn()
    try:
        yield conn
    finally:
        pool.putconn(conn)


class PollRequest(BaseModel):
    choice: str


@app.get("/")
def api_info():
    return {"service": "vibecheck-api", "options": {"a": OPTION_A, "b": OPTION_B}}


@app.get("/healthz")
def health_check():
    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
        return {"status": "ok", "database": "connected"}
    except Exception:
        raise HTTPException(status_code=500, detail="Database unavailable") from None


@app.post("/poll")
def poll(body: PollRequest):
    if body.choice not in ("a", "b"):
        raise HTTPException(status_code=400, detail="Invalid option. Must be 'a' or 'b'")

    with get_db() as conn:
        try:
            cursor = conn.cursor()
            cursor.execute("INSERT INTO polls (choice) VALUES (%s)", (body.choice,))
            conn.commit()
            cursor.close()
            logger.info("Vote recorded: %s", body.choice)
            return {"success": True, "choice": body.choice}
        except psycopg2.Error as e:
            conn.rollback()
            logger.error("Poll error: %s", e)
            raise HTTPException(status_code=500, detail=str(e)) from None


@app.get("/results")
def results():
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT choice, COUNT(*) AS count FROM polls GROUP BY choice")
        rows = cursor.fetchall()
        cursor.close()
        counts = {"a": 0, "b": 0}
        for row in rows:
            if row[0] in counts:
                counts[row[0]] = row[1]
        return counts
