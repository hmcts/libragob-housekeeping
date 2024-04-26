FROM ubuntu:24.04
ARG SCRIPT_FILE
ENV SCRIPT=${SCRIPT_FILE}

ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update -y && apt-get upgrade -y

RUN apt-get install -y --no-install-recommends \
  postgresql-client

COPY scripts/${SCRIPT_FILE} ${SCRIPT_FILE}
COPY sql sql
RUN chmod +x ${SCRIPT_FILE}

ENTRYPOINT bash "$SCRIPT"
