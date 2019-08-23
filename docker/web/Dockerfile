FROM ruby:2.6.3-alpine3.10

RUN apk add --upgrade build-base postgresql-contrib postgresql-dev bash libcurl git nodejs tzdata icu-libs chromium-chromedriver chromium ca-certificates

ENV RAILS_ROOT /var/www/fb-publisher
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY Gemfile.lock Gemfile ./
ARG BUNDLE_FLAGS
RUN bundle install --no-cache ${BUNDLE_FLAGS}

COPY . .

# allow access to port 3000
ENV APP_PORT 3000
EXPOSE $APP_PORT

# precompile assets
ARG RAILS_ENV=production
RUN RAILS_ENV=${RAILS_ENV} SECRET_KEY_BASE=$(bin/rake secret) bundle exec rake assets:precompile --trace

# run the rails server
ARG RAILS_ENV=production
CMD bundle exec rake db:migrate && bundle exec rake data:migrate && bundle exec rails s -e ${RAILS_ENV} -p ${APP_PORT} --binding=0.0.0.0
