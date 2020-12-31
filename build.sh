#!/bin/bash
set -e

name=austina
version="${1:-0.0.1}"
builder=tmp$(uuidgen)
 
docker build -t "$builder" . 1>&2

mkdir -p out

docker run --rm \
  --env-file ./.env \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "$builder" \
  ./buildImage.sh \
  > out/"$name"-"$version".vhd

docker image rm -f "$builder"

echo "tag = \"$version\"" > tag.auto.tfvars

