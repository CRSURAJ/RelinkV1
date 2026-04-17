#!/usr/bin/env bash
set -euo pipefail

echo "This script needs sudo access."
sudo -v

# Keep sudo alive while this script runs
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

TS_ROUTE="192.168.0.0/24"
TB_HOST="52.63.47.195"
TB_PORT="1883"

echo "=== Relink fast provisioning ==="

read -rsp "Enter Tailscale auth key: " TS_AUTHKEY
echo
read -rsp "Enter ThingsBoard access token: " TB_ACCESS_TOKEN
echo

if [ ! sudo -f /root/tb-gateway/docker-compose.yml ]; then
  echo "ERROR: /root/tb-gateway/docker-compose.yml not found"
  exit 1
fi

sudo mkdir -p /etc/relink
sudo tee /etc/relink/device.env >/dev/null <<EOF
TS_AUTHKEY=${TS_AUTHKEY}
TS_ADVERTISE_ROUTES=${TS_ROUTE}
TS_EXTRA_ARGS=--ssh

TB_HOST=${TB_HOST}
TB_PORT=${TB_PORT}
TB_ACCESS_TOKEN=${TB_ACCESS_TOKEN}
EOF

sudo chown root:root /etc/relink/device.env
sudo chmod 600 /etc/relink/device.env

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
