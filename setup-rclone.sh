#!/bin/bash
mkdir -p /root/.config/rclone
envsubst < /root/.config/rclone/rclone.conf.template > /root/.config/rclone/rclone.conf
chmod 600 /root/.config/rclone/rclone.conf
exec "$@"