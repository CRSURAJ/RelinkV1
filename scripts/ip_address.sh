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
