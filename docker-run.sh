#!/usr/bin/env zsh

set -e

if [ $# -lt 1 ]; then
    echo "Usage: ./docker-run.sh <SCRIPT_NAME> [additional k6 args]"
    exit 1
fi

# By default, we're assuming you created the extended k6 image as "grafana/k6-for-sql:latest".
# If not, override the name on the command-line with `IMAGE_NAME=...`.
IMAGE_NAME=${IMAGE_NAME:="grafana/xk6-sql-oracle:latest"}

docker run -v $PWD:/scripts -it --rm $IMAGE_NAME run /scripts/$1 ${@:2}
