import os
import sqlite3
import tempfile

import pytest
from fastapi.testclient import TestClient

from app.main import app, get_db_path


@pytest.fixture(autouse=True)
def use_temp_db(monkeypatch, tmp_path):
    db_file = tmp_path / "counter_test.db"
    monkeypatch.setenv("COUNTER_DB_PATH", str(db_file))
    # Force startup event to use new db path
    yield


@pytest.fixture()
def client():
    with TestClient(app) as client:
        yield client


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_counter_initializes_to_zero(client):
    response = client.get("/counter")
    assert response.status_code == 200
    assert response.json() == {"count": 0}


def test_increment_counter(client):
    response = client.post("/increment")
    assert response.status_code == 200
    assert response.json()["message"] == "counter incremented"
    assert response.json()["new_count"] == 1

    response = client.get("/counter")
    assert response.json()["count"] == 1


def test_reset_counter(client):
    client.post("/increment")
    response = client.post("/reset")
    assert response.status_code == 200
    assert response.json() == {"message": "counter reset", "count": 0}

    response = client.get("/counter")
    assert response.json()["count"] == 0


def test_persistence_between_clients(tmp_path, monkeypatch):
    db_file = tmp_path / "counter_persist.db"
    monkeypatch.setenv("COUNTER_DB_PATH", str(db_file))

    with TestClient(app) as client1:
        client1.post("/increment")
        client1.post("/increment")
        assert client1.get("/counter").json()["count"] == 2

    # Create a new client instance to verify SQLite file persistence.
    with TestClient(app) as client2:
        assert client2.get("/counter").json()["count"] == 2
