[![CircleCI](https://circleci.com/gh/ministryofjustice/fb-publisher/tree/master.svg?style=svg)](https://circleci.com/gh/ministryofjustice/fb-publisher/tree/master)

# Form Builder Publisher

This Ruby on Rails app allows users to deploy their forms in to [https://github.com/ministryofjustice/cloud-platform-environments](Cloud Platform)

## Environments

The app provides 2 environments to users. A `development` environment to test and preview changes and a `production` environment for public release

The Live environment can be found at https://fb-publisher-live.apps.live-1.cloud-platform.service.justice.gov.uk/services

Developers have a clone of this setup, the `test` environment which can be found at https://fb-publisher-test.apps.live-1.cloud-platform.service.justice.gov.uk/services

## User Access

Users use SSO with their @digital.justice.gov.uk google account in order to be able to access this publishing tool

## To run via Docker

You will need a running Docker daemon and docker-compose

```bash
make serve
```

Visit [http://localhost:3000](http://localhost:3000)

## Testing
The test suite is run through Docker locally and on CircleCi.

```
make spec
```
