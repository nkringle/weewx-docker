#!/usr/bin/env bash
set -e

chown weewx:weewx /home/weewx/weewx-data/weewx.conf || true
chown -R weewx:weewx /home/weewx/weewx-data/public_html || true

exec gosu weewx weewxd "$@"
