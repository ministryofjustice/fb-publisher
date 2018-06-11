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

You will need a running Docker daemon

```bash
# from the root directory of the application
docker build -t fb-publisher .
# this should start the application running as a daemon,
# in a container on port 3000, accessible from your
# local host at port 8000 (i.e. http://localhost:8000/).
# For possible configuration parameters, see the file dev_docker.sh
./dev_docker.sh

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
