FROM ruby:2.6.3-alpine3.9

ADD https://storage.googleapis.com/kubernetes-release/release/v1.6.4/bin/linux/amd64/kubectl /usr/local/bin/kubectl

RUN chmod +x /usr/local/bin/kubectl

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN chown -R appuser:appgroup .
RUN chown -R appuser:appgroup /usr/local/bin/kubectl
USER appuser

ARG RAILS_ENV=production
CMD bundle exec rake resque:work
