#!/bin/bash

CONTAINER_NAME="eva-evant-service-db"
CONTAINER_VOLUME="eva-evant-service-volume"

VOLUME_IS_EXISTS=$(docker volume ls | grep $CONTAINER_VOLUME)
CONTAINER_IS_EXISTS=$(docker container ps -a | grep $CONTAINER_NAME)
IS_RUNNING=$(docker ps | grep $CONTAINER_NAME)

DB_USER=user1
DB_PASSWORD=pass1
DB_NAME=$CONTAINER_NAME

if [[ "$IS_RUNNING" == *"$CONTAINER_NAME"* ]]; then
  echo ">>>  stop DB  <<<"
  docker stop $CONTAINER_NAME
  exit 0
fi

if [ -n "$VOLUME_IS_EXISTS" ]; then
  echo ">>> volume exists <<<"
else
  echo ">>> create volume <<<"
  docker volume create $CONTAINER_VOLUME
fi

if [ -n "$CONTAINER_IS_EXISTS" ]; then
  echo ">>>  run DB  <<<"
  docker container start $CONTAINER_NAME
else
  echo ">>> create DB  <<<"
  docker run \
    -v ${CONTAINER_VOLUME}:/var/lib/mysql \
    -p 5432:5432 -d \
    --name $CONTAINER_NAME \
    --env POSTGRES_USER=$DB_USER \
    --env POSTGRES_PASSWORD=$DB_PASSWORD \
    --env POSTGRES_DB=$DB_NAME \
    postgres:18rc1
fi
