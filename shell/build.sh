#!/bin/bash
docker build -t longshoreman-shell:"$1" ./main/
docker build -t longshoreman-shell-init:"$1" --build-arg LONGSHOREMAN_TAG="$1" ./init/
