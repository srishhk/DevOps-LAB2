#!/usr/bin/env bash
# Lab 2 / Q1-Q2 - Deploy to Minikube, scale, rolling update, failed update + rollback
# Run from the repo root after: minikube start
set -x

# Build images straight into Minikube's Docker daemon
eval "$(minikube docker-env)"
docker build -t lab2-web:1.0 .
docker build -t lab2-web:2.0 .

# Q1: deploy
kubectl apply -f k8s/configmap.yaml -f k8s/pv-pvc.yaml -f k8s/deployment.yaml -f k8s/service.yaml
kubectl rollout status deployment/lab2-web
kubectl get deploy,rs,pods,svc -o wide
URL=$(minikube service lab2-web-svc --url)
for i in 1 2 3 4 5 6; do curl -s "$URL"; echo; done

# Q2a: scale out and back
kubectl scale deployment/lab2-web --replicas=5
kubectl rollout status deployment/lab2-web
kubectl get pods -l app=lab2-web
kubectl scale deployment/lab2-web --replicas=3

# Q2b: rolling update to v2.0
kubectl set image deployment/lab2-web web=lab2-web:2.0
kubectl set env deployment/lab2-web APP_VERSION=2.0
kubectl annotate deployment/lab2-web kubernetes.io/change-cause="update to v2.0" --overwrite
kubectl rollout status deployment/lab2-web
curl -s "$URL"; echo

# Q2c: push a broken image, watch it fail, roll back
kubectl set image deployment/lab2-web web=lab2-web:does-not-exist
kubectl annotate deployment/lab2-web kubernetes.io/change-cause="bad image v3" --overwrite
kubectl rollout status deployment/lab2-web --timeout=40s || echo "ROLLOUT FAILED as expected"
kubectl get pods -l app=lab2-web
kubectl rollout history deployment/lab2-web
kubectl rollout undo deployment/lab2-web
kubectl rollout status deployment/lab2-web
kubectl get pods -l app=lab2-web
curl -s "$URL"; echo
