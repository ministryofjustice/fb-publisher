FROM ruby:2.6.3-alpine3.9

RUN curl -sL https://deb.nodesource.com/setup_12.x | sh -

RUN apk add --update --no-cache --virtual .build-deps build-base libgcrypt-dev libxml2-dev libxslt-dev nodejs postgresql-contrib postgresql-dev curl ca-certificates

WORKDIR /usr/src/app

COPY Gemfile.lock Gemfile ./
RUN bundle install --jobs 4 --retry 5 --deployment --without test development

COPY . .
