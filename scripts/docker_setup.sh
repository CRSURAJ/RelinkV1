# 0) Remove any conflicting packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" || true
done

# 1) Set up Docker's apt repository (Debian bookworm on ARM64)

sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo 'deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable' \
| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

# 2) Install the latest Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3) Add your user to the docker group (NOTE: if you run this with sudo -s, $USER may be root)
sudo usermod -aG docker "$USER"

# 4) Enable on boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo reboot
