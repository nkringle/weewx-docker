#!/usr/bin/env bash
set -e

# Ensure permissions are correct for mounted volumes
chown -R weewx:weewx /home/weewx/weewx-data || true

exec gosu weewx weewxd "$@"
