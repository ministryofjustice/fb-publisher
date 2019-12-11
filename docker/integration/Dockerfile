FROM ruby:2.6.3-alpine

RUN apk add build-base bash tzdata chromium-chromedriver chromium zlib-dev xorg-server postgresql-dev git curl

WORKDIR /usr/src/app

COPY Gemfile* .ruby-version ./
RUN gem update --system && gem install bundler
RUN bundle check || BUNDLE_JOBS=2 bundle install

COPY . .
