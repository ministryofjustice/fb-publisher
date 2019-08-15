FROM ruby:2.6.3-alpine3.10

RUN apk add --upgrade build-base postgresql-contrib postgresql-dev bash libcurl git nodejs tzdata icu-libs ca-certificates

RUN addgroup -g 1001 -S appgroup && \
  adduser -u 1001 -S appuser -G appgroup

ADD https://storage.googleapis.com/kubernetes-release/release/v1.6.4/bin/linux/amd64/kubectl /usr/local/bin/kubectl

RUN chmod +x /usr/local/bin/kubectl
RUN chown 1001:appgroup /usr/local/bin/kubectl

ENV RAILS_ROOT /var/www/fb-publisher
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY Gemfile.lock Gemfile ./
ENV BUNDLER_VERSION 2.0.2
RUN gem install bundler
ARG BUNDLE_FLAGS
RUN bundle install --jobs 4 --retry 5 ${BUNDLE_FLAGS}

COPY . .

RUN chown -R 1001:appgroup .

USER 1001

ARG RAILS_ENV=production
CMD bundle exec rake resque:work
