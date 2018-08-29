# Base image
FROM aldavidson/fb-publisher-base

# allow access to port 3000
ENV APP_PORT 3000
EXPOSE $APP_PORT

# precompile assets
ARG RAILS_ENV=production
RUN RAILS_ENV=${RAILS_ENV} bundle exec rake assets:precompile --trace

# run the rails server
ARG RAILS_ENV=production
CMD bundle exec rails s -e ${RAILS_ENV} -p ${APP_PORT} --binding=0.0.0.0
