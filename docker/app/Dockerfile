FROM ministryofjustice/ruby:2.5.1

RUN apt-get update && apt-get install -y nodejs postgresql-contrib libpq-dev

ENV RAILS_ROOT /var/www/fb-publisher
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY Gemfile.lock Gemfile ./
RUN bundle install --jobs 20 --retry 5

COPY . .
ADD . $RAILS_ROOT

ENV APP_PORT 3000
EXPOSE $APP_PORT

ARG RAILS_ENV=production
RUN RAILS_ENV=${RAILS_ENV} bundle exec rake assets:precompile --trace
ARG RAILS_ENV=production
CMD bundle exec rails s -e ${RAILS_ENV} -p ${APP_PORT} --binding=0.0.0.0
