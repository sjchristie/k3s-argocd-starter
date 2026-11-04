#!/usr/bin/env bash
set -euo pipefail

ARCH=$(dpkg --print-architecture)   # amd64 or arm64

echo "==> Fixing ownership of volume mount points..."
sudo chown -R vscode:vscode ~/.kube ~/.cloudflared ~/.config

echo "==> SSH key + config setup..."
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /home/vscode/.ssh-host/pi_key     ~/.ssh/pi_key
cp /home/vscode/.ssh-host/pi_key.pub ~/.ssh/pi_key.pub
chmod 600 ~/.ssh/pi_key && chmod 644 ~/.ssh/pi_key.pub
cat > ~/.ssh/config <<'CFG'
Host cp-01
    HostName 192.168.30.20
    User kubeadmin
    IdentityFile ~/.ssh/pi_key
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new

Host wrk-01
    HostName 192.168.30.21
    User kubeadmin
    IdentityFile ~/.ssh/pi_key
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
CFG
chmod 600 ~/.ssh/config

echo "==> Installing Vim and Neovim..."
sudo apt-get update && sudo apt-get install -y vim neovim iputils-ping dnsutils netcat-openbsd traceroute file

echo "==> Installing Helm (v3.17.1)..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | DESIRED_VERSION="v3.17.1" bash

echo "==> Installing cloudflared..."
curl -L --fail -o /tmp/cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb"
sudo dpkg -i /tmp/cloudflared.deb && rm /tmp/cloudflared.deb

echo "==> Installing k9s..."
curl -L --fail -o /tmp/k9s.tgz "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz"
sudo tar xzf /tmp/k9s.tgz -C /usr/local/bin k9s && rm /tmp/k9s.tgz

echo "==> Installing Starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "==> Configuring minimal Starship prompt with container badge..."
mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
add_newline = true

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[directory]
style = "bold blue"
truncate_to_repo = false

[git_branch]
disabled = true

[kubernetes]
disabled = true

[container]
symbol = "📦 "
format = '[$symbol]($style)'
style = "yellow"
disabled = false
EOF

echo "==> Enabling Starship in .bashrc..."
echo 'eval "$(starship init bash)"' >> ~/.bashrc

echo "==> Done. Environment is fully initialized."
