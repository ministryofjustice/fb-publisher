# fb-publisher
Form Builder Publisher Web application

# Pre-requisites

* ruby (2.5.0)
* [rubygems](https://rubygems.org/)
* [bundler](https://bundler.io/)
* [postgresql](https://www.postgresql.org/) - v10.3+
* (optional) [Docker](https://docker.com/) - tested on 18.03.1

# Setup

## To run via Docker

### Environment Variables

The application container requires several environment variables.
These are listed in the docker-compose.yml file, and most should be
self-explanatory

To run locally via docker, you'll need to construct the DATABASE_URL
correctly, taking care to set the host correctly - this should be
the IP of your host machine _as seen from inside the containers_
# You should add a .env file (git will ignore these files) to store
# your environment variables.
# important

You will need a running Docker daemon, and docker-compose

```bash

# First, build the containers:

# from the root directory of the application
docker compose build --build-arg RAILS_ENV=(env)
# ...where (env) should be replaced with a Rails environment name
# - ie. one of development, test, staging or production
# Then you can run them:
docker-compose up

# this should start the application running as a daemon,
# in a container on port 3000, accessible from your
# local host at port 8000 (i.e. http://localhost:8000/).

```

## To run as a native application
```bash
# install gems
bundle install
# set up the database
bundle exec rails db:setup db:migrate

# start the server
bundle exec rails s
```
