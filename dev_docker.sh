#!/bin/bash
HOST_IP=${HOST_IP:-"192.168.65.2"}
HOST_PORT=${HOST_PORT:-"8000"}
IMAGE_NAME=${IMAGE_NAME:-"fb-publisher"}
DB_NAME=${DB_NAME:-"fb-publisher_development"}
DB_USER=${DB_USER:-$(whoami)}
DATABASE_URL=${DATABASE_URL:-"postgres://${DB_USER}:${DB_PASSWORD}@${HOST_IP}/${DB_NAME}"}
CONTAINER_NAME=${CONTAINER_NAME:-"fb-publisher"}
RAILS_SERVE_STATIC_ASSETS=${RAILS_SERVE_STATIC_ASSETS:-"true"}

docker run  -p ${HOST_PORT}:3000 \
            --add-host="localhost:${HOST_IP}" \
            -e DATABASE_URL=${DATABASE_URL} \
            --name ${CONTAINER_NAME} \
            -d \
            ${IMAGE_NAME}
