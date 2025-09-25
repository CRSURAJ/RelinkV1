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
