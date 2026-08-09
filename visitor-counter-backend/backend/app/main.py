import os
import sqlite3
from threading import Lock
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

DEFAULT_DB_PATH = "counter.db"


def get_db_path() -> str:
    return os.getenv("COUNTER_DB_PATH", DEFAULT_DB_PATH)



def initialize_database(connection: sqlite3.Connection) -> None:
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS counter (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            value INTEGER NOT NULL
        )
        """
    )
    connection.execute(
        "INSERT OR IGNORE INTO counter (id, value) VALUES (1, 0)"
    )
    connection.commit()


def get_counter_value(connection: sqlite3.Connection) -> int:
    cursor = connection.execute("SELECT value FROM counter WHERE id = 1")
    row = cursor.fetchone()
    return row[0] if row is not None else 0


counter_lock = Lock()
db_connection: sqlite3.Connection | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    global db_connection
    db_path = get_db_path()
    db_dir = os.path.dirname(db_path)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)

    db_connection = sqlite3.connect(db_path, check_same_thread=False)
    initialize_database(db_connection)

    try:
        yield
    finally:
        # shutdown
        if db_connection is not None:
            db_connection.close()
            db_connection = None


app = FastAPI(
    title="Visitor Counter Backend",
    description="A simple backend for tracking visitor counts, built with FastAPI.",
    version="0.1.0",
    lifespan=lifespan,
)

# Enable CORS so the frontend (served on port 8001 during development) can call the API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8001", "http://127.0.0.1:8001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", summary="Health check")
def health_check() -> dict:
    """Return a simple health status."""
    return {"status": "ok"}


@app.get("/counter", summary="Get current counter")
def get_counter() -> dict:
    """Return the current counter value."""
    with counter_lock:
        assert db_connection is not None
        return {"count": get_counter_value(db_connection)}


@app.post("/increment", summary="Increment counter")
def increment_counter() -> dict:
    """Increment the stored counter and return the new value."""
    with counter_lock:
        assert db_connection is not None
        db_connection.execute(
            "UPDATE counter SET value = value + 1 WHERE id = 1"
        )
        db_connection.commit()
        return {
            "message": "counter incremented",
            "new_count": get_counter_value(db_connection),
        }


@app.post("/reset", summary="Reset counter")
def reset_counter() -> dict:
    """Reset the stored counter to zero."""
    with counter_lock:
        assert db_connection is not None
        db_connection.execute(
            "UPDATE counter SET value = 0 WHERE id = 1"
        )
        db_connection.commit()
        return {"message": "counter reset", "count": 0}
