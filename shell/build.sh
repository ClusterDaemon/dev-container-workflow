#!/bin/bash
minikube start
eval $(minikube -p minikube docker-env)
docker build -t longshoreman:"$1" ./main/
docker build -t longshoreman-init:"$1" --build-arg LONGSHOREMAN_TAG="$1" ./init/
