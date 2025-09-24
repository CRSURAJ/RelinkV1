curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
sudo systemctl start tailscaled
sudo tailscale up --auth-key=tskey-auth-kU1eF6C7ic11CNTRL-qVvoAWojrT9svN9EYcuJT958BpCJiNxUL
sudo tailscale set --ssh
sudo tailscale up --advertise-routes=192.168.0.0/24 --ssh
