FROM python:3.12-slim-bookworm

ENV MQTTSUBSCRIBE_VERSION=3.1.1 \
    NEOWX_VERSION=1.11 \
    AERO_VERSION=2.7.0 \
    WEEWXJSON_VERSION=1.3 \
    PAHOMQTT_VERSION=2 \
    WEEWX_VERSION=5.3.0 \
    EPHEM_VERSION=4.1.5 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1


# System deps:
# - rsyslog: used during build for weectl steps that expect syslog
# - gosu: drop privileges to weewx user
# - gcc: build some python wheels if needed
RUN apt-get update && apt-get install -y \
    rsyslog \
    gosu \
    gcc \
    ca-certificates \
    unzip \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir wheel paho-mqtt==${PAHOMQTT_VERSION} weewx==${WEEWX_VERSION} ephem==${EPHEM_VERSION}

RUN useradd -ms /bin/bash weewx

WORKDIR /home/weewx
RUN chown weewx:weewx /home/weewx

# Initialize weewx and install extensions
RUN gosu weewx weectl station create --no-prompt

# Replace generated config with your known-good console-logging config
COPY data/weewx.conf /home/weewx/weewx-data/weewx.conf
RUN chown weewx:weewx /home/weewx/weewx-data/weewx.conf


RUN gosu weewx weectl extension install https://github.com/neoground/neowx-material/releases/download/${NEOWX_VERSION}/neowx-material-${NEOWX_VERSION}.zip --yes
RUN gosu weewx weectl extension install https://github.com/teeks99/weewx-json/releases/download/v${WEEWXJSON_VERSION}/weewx-json_${WEEWXJSON_VERSION}.tar.gz --yes
RUN gosu weewx weectl extension install https://github.com/sankara/weewx-skin-aero/releases/download/v${AERO_VERSION}/weewx-aero-v${AERO_VERSION}.zip
RUN gosu weewx weectl extension install https://github.com/weewx-mqtt/subscribe/archive/refs/tags/v${MQTTSUBSCRIBE_VERSION}.zip --yes


# NeoWX overrides
COPY overrides/neowx-material/skin.conf /home/weewx/weewx-data/skins/neowx-material/skin.conf
COPY overrides/neowx-material/weathertv.html.tmpl /home/weewx/weewx-data/skins/neowx-material/weathertv.html.tmpl

#Aero overrides
COPY overrides/Aero/skin.conf /home/weewx/weewx-data/skins/neowx-material/skin.conf

# JSON overrides
COPY overrides/JSON/skin.conf /home/weewx/weewx-data/skins/JSON/skin.conf
COPY overrides/JSON/weewx-homebridge.json.tmpl /home/weewx/weewx-data/skins/JSON/weewx-homebridge.json.tmpl

RUN chown weewx:weewx \
    /home/weewx/weewx-data/skins/neowx-material/skin.conf \
    /home/weewx/weewx-data/skins/neowx-material/weathertv.html.tmpl \
    /home/weewx/weewx-data/skins/JSON/skin.conf \
    /home/weewx/weewx-data/skins/JSON/weewx-homebridge.json.tmpl \
    /home/weewx/weewx-data/skins/Aero/skin.conf

RUN gosu weewx weectl station reconfigure --no-prompt --no-backup

COPY entry.sh /home/weewx/entry.sh
RUN chmod 755 /home/weewx/entry.sh

ENTRYPOINT ["/home/weewx/entry.sh"]
