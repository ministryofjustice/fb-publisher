ARG RUNNER_IMAGE=aldavidson/fb-runner-node:latest
FROM $RUNNER_IMAGE

RUN mkdir -p /usr/app/metadata
ARG JSON_DIR=./json

# NOTE: runner always looks in ${SERVICEDATA}/metadata
# for its json, so that it can cache local packages etc
# along side it. Need to be aware of this as a possible
# 'gotcha' when asking users for json_sub_dir
COPY $JSON_DIR /usr/app/metadata/
ENV SERVICEDATA=/usr/app/
ENV BIND_IP="0.0.0.0"
