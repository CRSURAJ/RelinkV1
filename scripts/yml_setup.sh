echo "pi ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/010-pi-nopasswd >/dev/null
sudo chmod 0440 /etc/sudoers.d/010-pi-nopasswd
mkdir -p ~/tb-gateway
curl -fsSL https://raw.githubusercontent.com/CRSURAJ/RelinkV1/main/scripts/tb-gateway/docker-compose.yml \
  -o ~/tb-gateway/docker-compose.yml
cd ~/tb-gateway
docker compose pull
docker compose up -d
