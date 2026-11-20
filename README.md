# DevOps Lab 2: Containerization & Kubernetes Orchestration

**Student:** Srishti Kainth | **Roll No.:** 2301730175 | **Email:** srishtikainth2@gmail.com
**Course:** DevOps and Automation (ENSP461)
**Environment:** Ubuntu 24.04 LTS, Docker, Docker Compose, Minikube, kubectl, GitHub Actions

A Flask app with a Redis visit counter, run as a single container, as a Docker Compose stack, and on Kubernetes, with automated deployment through GitHub Actions.

| Path | Purpose | Question |
|---|---|---|
| `app.py`, `test_app.py` | Flask app (`/`, `/healthz`, `/ready`) and 3 pytest tests | Q4 |
| `Dockerfile` | Multi-stage build, non-root user, health check | Q4 |
| `docker-compose.yml` | Web app + Redis, health-checked startup, named volume | Q5 |
| `demos/storage_demo.sh` | Container layer vs named volume vs bind mount | Q6 |
| `demos/network_demo.sh` | Default bridge vs custom bridge, DNS, isolation | Q7 |
| `k8s/` | ConfigMap, PV/PVC, Deployment (3 replicas), NodePort Service | Q1 |
| `demos/k8s_rollout_demo.sh` | Scaling, rolling update, failed update and rollback | Q2 |
| `.github/workflows/cd.yml` | Test → build → deploy to a kind cluster → rollout check → smoke test | Q8 |

## Setup (Ubuntu 24.04)

```bash
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER && newgrp docker
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
sudo snap install kubectl --classic
```

## Run

```bash
# Docker
docker build -t lab2-web:1.0 .
docker run -d --name lab2-single -p 8000:5000 lab2-web:1.0 && curl localhost:8000

# Docker Compose
docker compose up -d --build && curl localhost:8000

# Storage and networking experiments
bash demos/storage_demo.sh
bash demos/network_demo.sh

# Kubernetes
minikube start --driver=docker
eval $(minikube docker-env) && docker build -t lab2-web:1.0 .
kubectl apply -f k8s/ && kubectl rollout status deployment/lab2-web
curl $(minikube service lab2-web-svc --url)
bash demos/k8s_rollout_demo.sh
```

## Tests

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt && pytest -v
```

The CD workflow runs on every push to `main` (see the **Actions** tab).
