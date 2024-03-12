FROM ubuntu:22.04
ARG SCRIPT_FILE="housekeeping.sh"

ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update -y && apt-get upgrade -y && useradd -m libragob

RUN apt-get install -y --no-install-recommends \
  postgresql-client

COPY scripts/${SCRIPT_FILE} /home/libragob/${SCRIPT_FILE}
RUN chmod +x /home/libragob/${SCRIPT_FILE}

USER libragob

ENTRYPOINT ["./home/libragob/${SCRIPT_FILE}"]
