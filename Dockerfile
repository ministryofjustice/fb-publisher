FROM ministryofjustice/ruby:2.5.1-light

RUN apk update && apk add build-base nodejs postgresql-dev

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --binstubs

COPY . .


ENV UNICORN_PORT 3000
EXPOSE $UNICORN_PORT

RUN RAILS_ENV=production bundle exec rake assets:precompile --trace
RUN RAILS_ENV=production bundle exec rake db:migrate

ENTRYPOINT ["bundle exec puma -C config/puma.rb"]
