#!/usr/bin/env bash
set -euo pipefail

# 1) Install & build mbusd
sudo apt update
sudo apt install -y git build-essential cmake

cd ~
if [ ! -d mbusd ]; then
  git clone https://github.com/3cky/mbusd.git
fi
cd mbusd
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
sudo make install

# Quick check (non-fatal if missing)
which mbusd || true
mbusd -h | head -n 5 || true

# 2) Create config for /dev/ttyAMA5 (9600 8N1 default; RS-485 enabled)
sudo install -d -m 0755 /etc/mbusd
sudo tee /etc/mbusd/mbusd-ttyAMA5.conf >/dev/null <<'EOF'
loglevel = 2
logfile  = /var/log/mbusd.log

device   = /dev/ttyAMA5
speed    = 9600
mode     = 8n1
# If you see timeouts, try enabling kernel RS-485:
enable_rs485 = yes
trx_control = addc

address  = 0.0.0.0
port     = 502
maxconn  = 32
timeout  = 60

retries  = 3
pause    = 100
wait     = 500
EOF

# 3) Systemd service for daemon mode on /dev/ttyAMA5
sudo tee /etc/systemd/system/mbusd-ttyAMA5.service >/dev/null <<'EOF'
[Unit]
Description=mbusd (Modbus TCP↔Serial) on /dev/ttyAMA5
After=network-online.target dev-ttyAMA5.device
Wants=network-online.target
Requires=dev-ttyAMA5.device

[Service]
Type=forking
User=root
# Wait (up to 30s) for /dev/ttyAMA5 to exist before starting
ExecStartPre=/bin/sh -c 'for i in $(seq 1 30); do [ -e /dev/ttyAMA5 ] && exit 0; sleep 1; done; echo "/dev/ttyAMA5 not found" >&2; exit 1'
# Start mbusd as a daemon using your config
ExecStart=/usr/bin/mbusd -c /etc/mbusd/mbusd-ttyAMA5.conf
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now mbusd-ttyAMA5.service
systemctl status mbusd-ttyAMA5 --no-pager -l || true
sudo ss -tlnp | grep :502 || true

# Notes:
# Foreground test (manual):
#   sudo /usr/bin/mbusd -c /etc/mbusd/mbusd-ttyAMA5.conf
#   sudo ss -tlnp | grep :502
# Example mbpoll test (adjust unit/register):
#   mbpoll -m tcp -a 1 -r 100 -c 1 -t 3 -1 127.0.0.1 -p 502
