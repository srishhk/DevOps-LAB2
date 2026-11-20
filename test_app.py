import importlib

import pytest


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setenv("DATA_DIR", str(tmp_path))
    monkeypatch.setenv("REDIS_HOST", "")
    import app as app_module
    importlib.reload(app_module)
    app_module.app.config["TESTING"] = True
    with app_module.app.test_client() as c:
        yield c


def test_index_counts_visits(client):
    assert client.get("/").get_json()["visits"] == 1
    assert client.get("/").get_json()["visits"] == 2


def test_healthz(client):
    assert client.get("/healthz").get_json()["status"] == "alive"


def test_ready_without_redis(client):
    res = client.get("/ready")
    assert res.status_code == 200
    assert res.get_json()["status"] == "ready"
