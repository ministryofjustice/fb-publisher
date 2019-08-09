FROM ministryofjustice/ruby:2.6.3

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
RUN bundle install --no-cache ${BUNDLE_FLAGS}

COPY . .

RUN groupadd -r deploy && useradd -m -u 1001 -r -g deploy deploy
RUN chown -R deploy:deploy .
USER 1001

# allow access to port 3000
ENV APP_PORT 3000
EXPOSE $APP_PORT

# precompile assets
ARG RAILS_ENV=production
RUN RAILS_ENV=${RAILS_ENV} SECRET_KEY_BASE=$(bin/rake secret) bundle exec rake assets:precompile --trace

# run the rails server
ARG RAILS_ENV=production
CMD bundle exec rake db:migrate && bundle exec rake data:migrate && bundle exec rails s -e ${RAILS_ENV} -p ${APP_PORT} --binding=0.0.0.0
