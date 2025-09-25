echo "pi ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/010-pi-nopasswd >/dev/null
sudo chmod 0440 /etc/sudoers.d/010-pi-nopasswd


sudo apt purge --auto-remove mesa-libgallium libllvm15 squeekboard -y
sudo apt purge --auto-remove mesa-vulkan-drivers mesa-libgallium firmware-nvidia-graphics firmware-intel-graphics \
  gcc-12 g++-12 cpp-12 libllvm15 python3-mypy libperl5.36 libpython3.11-dev \
  python3-numpy python-babel-localedata mkvtoolnix libz3-4 libgs10 -y
sudo apt purge --auto-remove \
  mesa-libgallium libglx-mesa0 libgl1-mesa-dri libgl1 -y
sudo apt autoremove --purge   
sudo apt clean
sudo journalctl --vacuum-size=50M

sudo apt install -y modemmanager network-manager libqmi-utils libmbim-utils
sudo apt install python3-venv python3-full -y
sudo apt install build-essential -y

sudo systemctl enable --now NetworkManager
sudo systemctl disable --now dhcpcd 2>/dev/null || true
sudo nmcli con mod "Wired connection 1" \
  connection.interface-name eth0 \
  connection.permissions "" \
  connection.autoconnect yes \
  connection.autoconnect-priority 100 \
  connection.autoconnect-retries -1 \
  connection.wait-device-timeout 120000 \
  ipv4.method manual \
  ipv4.addresses 192.168.0.110/24 \
  ipv4.gateway "" \
  ipv4.never-default yes \
  ipv4.dns "" \
  ipv6.method ignore

sudo nmcli con up "Wired connection 1"

sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
sudo systemctl start tailscaled
sudo tailscale up --auth-key=
sudo tailscale set --ssh
sudo tailscale up --advertise-routes=192.168.0.0/24 --ssh


# Install Picocom
sudo apt install -y picocom

# Append to /boot/firmware/config.txt (same content you’d add via nano)
sudo tee -a /boot/firmware/config.txt >/dev/null <<'CFG'
# For more options and information see
# http://rptl.io/configtxt
# Some settings may impact device functionality. See link above for details

# Uncomment some or all of these to enable the optional hardware interfaces
#dtparam=i2c_arm=on
#dtparam=i2s=on
#dtparam=spi=on

# Enable audio (loads snd_bcm2835)
dtparam=audio=on

# Additional overlays and parameters are documented
# /boot/firmware/overlays/README

# Automatically load overlays for detected cameras
camera_auto_detect=1

# Automatically load overlays for detected DSI displays
display_auto_detect=1

# Automatically load initramfs files, if found
auto_initramfs=1

# Enable DRM VC4 V3D driver
dtoverlay=vc4-kms-v3d
max_framebuffers=2

# Don't have the firmware create an initial video= setting in cmdline.txt.
# Use the kernel's default instead.
disable_fw_kms_setup=1

# Run in 64-bit mode
arm_64bit=1

# Disable compensation for displays with overscan
disable_overscan=1

# Run as fast as firmware / board allows
arm_boost=1

#Enabling RS485 Ports
enable_uart=1
dtoverlay=uart5,txd5_pin=12,rxd5_pin=13

[cm4]
# Enable host mode on the 2711 built-in XHCI USB controller.
# This line should be removed if the legacy DWC2 controller is required
# (e.g. for USB device mode) or if USB support is not required.
otg_mode=1

[cm5]
dtoverlay=dwc2,dr_mode=host

[all]
CFG

# (Run manually if you want a live serial session)
# picocom -b 115200 /dev/ttyAMA5

# Download MBPOLL
sudo apt install -y mbpoll

# Download vnstat and enable
sudo apt install -y vnstat
sudo systemctl enable --now vnstat

# Limit journald size and restart
sudo sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=10M/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald


# 1) Install & build mbusd

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

# 0) Remove any conflicting packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" || true
done
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo 'deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable' \
| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker $USER

sudo systemctl enable docker.service
sudo systemctl enable containerd.service


mkdir -p ~/tb-gateway
curl -fsSL https://raw.githubusercontent.com/CRSURAJ/RelinkV1/main/scripts/tb-gateway/docker-compose.yml \
  -o ~/tb-gateway/docker-compose.yml
cd ~/tb-gateway
docker compose up -d
sudo apt full-upgrade -y
sudo reboot
