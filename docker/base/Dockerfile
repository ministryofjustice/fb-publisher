FROM ministryofjustice/ruby:2.5.1

RUN apt-get update && apt-get install -y nodejs postgresql-contrib libpq-dev

ENV RAILS_ROOT /var/www/fb-publisher
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY Gemfile.lock Gemfile ./
RUN bundle install --jobs 20 --retry 5

COPY . .
ADD . $RAILS_ROOT
