curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
sudo systemctl start tailscaled
sudo tailscale up
sudo tailscale set --ssh
