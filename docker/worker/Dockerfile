FROM ministryofjustice/ruby:2.5.1

# https://github.com/nodesource/distributions/blob/master/README.md#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

RUN apt-get update && apt-get install -y nodejs postgresql-contrib libpq-dev
ENV RAILS_ROOT /var/www/fb-publisher
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY Gemfile.lock Gemfile ./
ENV BUNDLER_VERSION 2.0.2
RUN gem install bundler
ARG BUNDLE_FLAGS
RUN bundle install --jobs 4 --retry 5 ${BUNDLE_FLAGS}

COPY . .

# install kubectl as described at
# https://kubernetes.io/docs/tasks/tools/install-kubectl/
RUN apt-get update && apt-get install -y apt-transport-https
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN touch /etc/apt/sources.list.d/kubernetes.list
RUN echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

RUN groupadd -r deploy && useradd -m -u 1001 -r -g deploy deploy
RUN chown -R deploy:deploy .
USER 1001

ARG RAILS_ENV=production
CMD bundle exec rake resque:work
