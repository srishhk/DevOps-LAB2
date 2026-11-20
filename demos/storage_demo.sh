#!/usr/bin/env bash
# Lab 2 / Q6 - Docker storage: container layer vs named volume vs bind mount
set -x

# 6.1 Data written inside the container layer is lost when the container is removed
docker run --name ephemeral-demo alpine sh -c 'echo "srishti-data" > /tmp/note.txt && cat /tmp/note.txt'
docker rm ephemeral-demo
docker run --rm --name ephemeral-demo2 alpine sh -c 'cat /tmp/note.txt || echo "FILE GONE - container layer is not persistent"'

# 6.2 Named volume survives container removal
docker volume create lab2-vol
docker run --rm -v lab2-vol:/data alpine sh -c 'echo "saved in a named volume" > /data/note.txt'
docker run --rm -v lab2-vol:/data alpine cat /data/note.txt
docker volume inspect lab2-vol

# 6.3 Bind mount shares a host folder with the container
mkdir -p "$(pwd)/host_data"
echo "edited on the host" > "$(pwd)/host_data/config.txt"
docker run -d --name bind-demo -v "$(pwd)/host_data:/app/config" alpine sleep 300
docker exec bind-demo cat /app/config/config.txt
docker exec bind-demo sh -c 'echo "written from the container" >> /app/config/config.txt'
cat "$(pwd)/host_data/config.txt"

# Clean up
docker rm -f bind-demo
docker volume rm lab2-vol
