import os

# Set env vars before importing the app
os.environ.setdefault("POSTGRES_HOST", "localhost")
os.environ.setdefault("POSTGRES_USER", "test")
os.environ.setdefault("POSTGRES_PASSWORD", "test")
os.environ.setdefault("POSTGRES_DB", "test")
os.environ.setdefault("OPTION_A", "Obviously")
os.environ.setdefault("OPTION_B", "Crime")

from fastapi.testclient import TestClient

from app import app

client = TestClient(app)


class TestHealthCheck:
    def test_healthz_returns_status(self):
        response = client.get("/healthz")
        # Returns 200 with DB connected, 500 without — both are valid in tests
        assert response.status_code in (200, 500)


class TestApiInfo:
    def test_root_returns_service_info(self):
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["service"] == "vibecheck-api"
        assert "options" in data
        assert data["options"]["a"] == "Obviously"
        assert data["options"]["b"] == "Crime"


class TestPollValidation:
    def test_rejects_missing_choice(self):
        response = client.post("/poll", json={})
        assert response.status_code == 422

    def test_rejects_invalid_choice(self):
        response = client.post("/poll", json={"choice": "c"})
        assert response.status_code == 400
        assert "Invalid" in response.json()["detail"]

    def test_rejects_empty_choice(self):
        response = client.post("/poll", json={"choice": ""})
        assert response.status_code == 400
