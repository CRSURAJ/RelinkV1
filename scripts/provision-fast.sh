#!/usr/bin/env bash
set -euo pipefail

echo "This script needs sudo access."
sudo -v

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
TS_ROUTE="192.168.0.0/24"
TB_HOST="52.63.47.195"
TB_PORT="1883"

echo "=== Relink fast provisioning ==="

read -rsp "Enter Tailscale auth key: " TS_AUTHKEY
echo
read -rsp "Enter ThingsBoard access token: " TB_ACCESS_TOKEN
echo

sudo mkdir -p /etc/relink
sudo tee /etc/relink/device.env >/dev/null <<EOF
TS_AUTHKEY=${TS_AUTHKEY}
TS_ADVERTISE_ROUTES=${TS_ROUTE}
TS_EXTRA_ARGS=--ssh

TB_HOST=${TB_HOST}
TB_PORT=${TB_PORT}
TB_ACCESS_TOKEN=${TB_ACCESS_TOKEN}
EOF

sudo mkdir -p /home/pi/tb-gateway
sudo cp -a /root/tb-gateway/. /home/pi/tb-gateway/
sudo chown -R pi:pi /home/pi/tb-gateway

sudo systemctl restart docker
sudo systemctl restart tailscaled

sudo tailscale logout || true
sudo tailscale up --auth-key="${TS_AUTHKEY}" --advertise-routes="${TS_ROUTE}" --ssh

cd /home/pi/tb-gateway
sudo docker compose --env-file /etc/relink/device.env up -d

echo
echo "=== Done ==="
echo "device.env written to /etc/relink/device.env"
echo
sudo docker compose --env-file /etc/relink/device.env ps
echo
tailscale status
