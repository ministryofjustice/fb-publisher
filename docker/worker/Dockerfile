FROM ruby:2.7.7-buster

# https://github.com/nodesource/distributions/blob/master/README.md#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

RUN apt-get update && apt-get install -y nodejs postgresql-contrib libpq-dev

ENV RAILS_ROOT /var/www/fb-publisher
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

RUN groupadd -r deploy && useradd -m -u 1001 -r -g deploy deploy
RUN chown deploy:deploy /var/www/fb-publisher

COPY --chown=deploy:deploy Gemfile Gemfile.lock .ruby-version ./
ENV BUNDLER_VERSION 2.1.4
RUN gem install bundler
ARG BUNDLE_FLAGS="--jobs 2 --no-cache --without development test"
RUN bundle install ${BUNDLE_FLAGS}

ADD --chown=deploy:deploy https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem ./rds-ca-2019-root.pem
ADD --chown=deploy:deploy https://s3.amazonaws.com/rds-downloads/rds-ca-2015-root.pem ./rds-ca-2015-root.pem
RUN cat ./rds-ca-2019-root.pem > ./rds-ca-bundle-root.crt
RUN cat ./rds-ca-2015-root.pem >> ./rds-ca-bundle-root.crt
RUN chown deploy:deploy ./rds-ca-bundle-root.crt

COPY --chown=deploy:deploy . .

# install kubectl as described at
# https://kubernetes.io/docs/tasks/tools/install-kubectl/
RUN apt-get update && apt-get install -y apt-transport-https
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN touch /etc/apt/sources.list.d/kubernetes.list
RUN echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

USER 1001

ARG RAILS_ENV=production
CMD bundle exec rake resque:work
