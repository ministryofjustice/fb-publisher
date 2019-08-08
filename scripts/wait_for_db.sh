#!/bin/sh

set -e

host="$1"
username="$2"
until docker-compose exec -e PGPASSWORD=root -T db psql -h 127.0.0.1 -U postgres -c '\q'; do
    >&2 echo "Postgres is unavailable - sleeping";
    sleep 1
done

>&2 echo "Postgres is up - executing command";
