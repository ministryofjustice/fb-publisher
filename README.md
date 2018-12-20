# fb-publisher
Form Builder Publisher Web application

# Pre-requisites

### To run the web app only
* ruby (2.5.0)
* [rubygems](https://rubygems.org/)
* [bundler](https://bundler.io/)
* [postgresql](https://www.postgresql.org/) - v10.3+

### To perform deployments
* [Docker](https://docker.com/) - tested on 18.03.1
* [Kubernetes CLI](https://kubernetes.io/) - Homebrew package `kubernetes-cli` v1.11+
* [AWS CLI](https://aws.amazon.com/cli) - tested on v1.11.120

### To run deployed services locally
* [Minikube](https://github.com/kubernetes/minikube) - v0.26.1+

# Setup

## To deploy and run on Cloud Platforms

See `fb-publisher-deploy`

## To run via Docker

### Environment Variables

The application container requires several environment variables.
These are listed in the docker-compose.yml file, and most should be
self-explanatory

To run *locally* via docker, you'll need to construct the DATABASE_URL
correctly, taking care to set the host correctly - this should be
the IP of your host machine _as seen from inside the containers_

You should add a .env file (git will ignore these files) to store your
environment variables. You can still override them per-command if needed

*speak to Al about the AUTH0_ variables!*

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


# About the code

I've tried to follow some simple principles when building this app.
Firstly, the [MoJ Digital Development Principles](http://bit.ly/27jc8ia) and
[Architecture Principles](https://docs.google.com/document/d/1XBTuCw0y--4fZpHcTLWilSFx_qz3aewTiWYJGTZU4sA/edit#heading=h.41v69p9hpl15)


There are a few more specific rules-of-thumb I've followed  - in no particular
 order:

1. Favour off-the-shelf componenents and services over roll-your-own
2. Aim for a consistent (not identical) experience between local dev & live deployment
3. Test with Rspec, focus on functional testing over unit tests to avoid
  'test paralysis'
4. Bearing in mind that this app may be refactored in future to expose functions as
  a remote API -
5. Keep controllers and models thin
6. All significant workflow should be encapsulated in stateless service objects
7. Service objects should delegate to platform-specific adapters (which may be
  stateful) to do the actual work


The application is built on Ruby on Rails 5, using ActiveJob for offline
processing.
