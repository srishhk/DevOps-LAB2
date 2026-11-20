#!/usr/bin/env bash
# Lab 2 / Q7 - Docker networking: default bridge vs user-defined bridge
set -x

# 7.1 Default bridge: containers get IPs but cannot resolve each other by name
docker run -d --name backend-default nginx:alpine
docker run --rm alpine sh -c 'ping -c 2 backend-default || echo "NAME RESOLUTION FAILED on default bridge"'
BACKEND_IP=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' backend-default)
docker run --rm alpine ping -c 2 "$BACKEND_IP"
docker rm -f backend-default

# 7.2 Custom bridge network
docker network create --driver bridge --subnet 172.28.0.0/16 lab2-custom-net
docker network inspect lab2-custom-net

# 7.3 Containers on the custom network resolve each other by name (embedded DNS 127.0.0.11)
docker run -d --name backend-server --network lab2-custom-net nginx:alpine
docker run --rm --name frontend-client --network lab2-custom-net alpine sh -c \
  'cat /etc/resolv.conf; ping -c 2 backend-server; wget -qO- http://backend-server | head -n 4'

# 7.4 Isolation: a container on another network cannot reach backend-server
docker network create lab2-other-net
docker run --rm --network lab2-other-net alpine sh -c 'ping -c 2 -W 1 backend-server || echo "ISOLATED - different network"'

# Clean up
docker rm -f backend-server
docker network rm lab2-custom-net lab2-other-net
