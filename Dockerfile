FROM ministryofjustice/ruby:2.5.0

RUN apt-get update && apt-get install -y nodejs postgresql-contrib libpq-dev

RUN mkdir /app
WORKDIR /app

COPY Gemfile.lock Gemfile ./
RUN bundle install

COPY . .
ADD . /app

ENV UNICORN_PORT 3000
EXPOSE $UNICORN_PORT

RUN RAILS_ENV=production bundle exec rake assets:precompile --trace
CMD bundle exec rails s production
