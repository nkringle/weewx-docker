FROM python:3.12-slim-bookworm

ENV MQTTSUBSCRIBE_VERSION=3.1.1 \
    NEOWX_VERSION=1.11 \
    WEEWXJSON_VERSION=1.3 \ 
    PAHOMQTT_VERSION=2 \
    WEEWX_VERSION=5.3.0 \
    EPHEM_VERSION=4.1.5


# System deps:
# - rsyslog: used during build for weectl steps that expect syslog
# - gosu: drop privileges to weewx user
# - gcc: build some python wheels if needed
# - procps: provides pkill (and other proc tools)
RUN apt-get update && apt-get install -y \
    rsyslog \
    gosu \
    gcc \
    procps \
 && rm -rf /var/lib/apt/lists/*

# Quiet rsyslog in containers: disable kernel logging (/proc/kmsg) which is blocked
RUN sed -i 's/^\(module(load="imklog".*\)\s*$/# \1/' /etc/rsyslog.conf || true

RUN pip install wheel paho-mqtt==${PAHOMQTT_VERSION} weewx==${WEEWX_VERSION} ephem==${EPHEM_VERSION}

RUN useradd -ms /bin/bash weewx

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /home/weewx
RUN chown weewx:weewx /home/weewx
# Initialize weewx and install extensions
RUN rsyslogd && gosu weewx weectl station create --no-prompt && pkill rsyslogd || true

RUN rsyslogd && gosu weewx weectl extension install \
    https://github.com/neoground/neowx-material/releases/download/${NEOWX_VERSION}/neowx-material-${NEOWX_VERSION}.zip \
    --yes \
 && pkill rsyslogd || true

RUN rsyslogd && gosu weewx weectl extension install \
    https://github.com/teeks99/weewx-json/releases/download/v${WEEWXJSON_VERSION}/weewx-json_${WEEWXJSON_VERSION}.tar.gz \
    --yes \
 && pkill rsyslogd || true

RUN rsyslogd && gosu weewx weectl extension install \
    https://github.com/weewx-mqtt/subscribe/archive/refs/tags/v${MQTTSUBSCRIBE_VERSION}.zip \
    --yes \
 && pkill rsyslogd || true

RUN rsyslogd && gosu weewx weectl station reconfigure --no-prompt --no-backup && pkill rsyslogd || true
COPY entry.sh /home/weewx/entry.sh
RUN chmod 755 /home/weewx/entry.sh

ENTRYPOINT ["/home/weewx/entry.sh"]
