ARG RUNNER_IMAGE=aldavidson/fb-sample-runner:latest
FROM $RUNNER_IMAGE

RUN mkdir -p /usr/app/metadata
ARG JSON_DIR=./json
COPY $JSON_DIR /usr/app/metadata/
