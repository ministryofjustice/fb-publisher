FROM ruby:2.6.3-alpine3.10

RUN apk add build-base postgresql-contrib postgresql-dev bash libcurl git nodejs tzdata icu-libs
RUN apk --no-cache add ca-certificates

ADD https://storage.googleapis.com/kubernetes-release/release/v1.6.4/bin/linux/amd64/kubectl /usr/local/bin/kubectl

RUN set -x && \
    apk add --no-cache curl ca-certificates && \
    chmod +x /usr/local/bin/kubectl && \
    \
    # Create non-root user (with a randomly chosen UID/GUI).
    adduser kubectl -Du 2342 -h /config && \
    \
    # Basic check it works.
    kubectl version --client


RUN addgroup -g 1001 -S appgroup && \
  adduser -u 1001 -S appuser -G appgroup

ENV RAILS_ROOT /app
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY Gemfile.lock Gemfile ./
ENV BUNDLER_VERSION 2.0.2
RUN gem install bundler
RUN bundle install --jobs 4 --retry 5 --deployment --without test development

COPY . .

RUN chown -R 1001:appgroup .

USER 1001

ARG RAILS_ENV=production
CMD bundle exec rake resque:work
