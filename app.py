"""Lab 2 application: Flask service with a Redis-backed visit counter.

Used for Docker, Docker Compose and Kubernetes experiments.
Author: Srishti Kainth (2301730175)
"""
import os
import socket

from flask import Flask, jsonify

APP_VERSION = os.getenv("APP_VERSION", "1.0")
GREETING = os.getenv("GREETING", "Hello from Lab 2")
REDIS_HOST = os.getenv("REDIS_HOST", "")
DATA_DIR = os.getenv("DATA_DIR", "/data")

app = Flask(__name__)
_redis = None


def get_redis():
    """Return a Redis client, or None if Redis is not configured/reachable."""
    global _redis
    if not REDIS_HOST:
        return None
    if _redis is None:
        import redis
        _redis = redis.Redis(host=REDIS_HOST, port=6379, socket_connect_timeout=1)
    return _redis


def count_visit():
    r = get_redis()
    if r is not None:
        try:
            return int(r.incr("visits")), "redis"
        except Exception:
            pass
    # Fallback: keep the counter in a file so volume experiments can use it.
    os.makedirs(DATA_DIR, exist_ok=True)
    path = os.path.join(DATA_DIR, "visits.txt")
    n = int(open(path).read()) + 1 if os.path.exists(path) else 1
    with open(path, "w") as f:
        f.write(str(n))
    return n, "file"


@app.route("/")
def index():
    visits, backend = count_visit()
    return jsonify(
        message=GREETING,
        version=APP_VERSION,
        pod=socket.gethostname(),
        visits=visits,
        counter_backend=backend,
    )


@app.route("/healthz")
def healthz():
    return jsonify(status="alive")


@app.route("/ready")
def ready():
    r = get_redis()
    if r is not None:
        try:
            r.ping()
        except Exception:
            return jsonify(status="redis-unavailable"), 503
    return jsonify(status="ready", version=APP_VERSION)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))  # nosec B104
