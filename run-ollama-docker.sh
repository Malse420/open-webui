#!/bin/bash

host_port=11434
container_port=11434
docker rm -f ollama || true
docker pull ollama/ollama:latest

docker_args="-d -v ollama:/root/.ollama -p $host_port:$container_port --name ollama ollama/ollama"

docker run $docker_args

docker image prune -f
