#!/bin/bash
# Hint: set tool versions via environmnet

apt_packages=(
    curl
    unzip
    libreadline-dev
    dialog
    man
    openssl
    dirmngr
    iputils-arping
    iputils-clockdiff
    iputils-ping
    iputils-tracepath
    traceroute
    nmap
    ttyd
    tmux
    vim
    git
    gh
    jq
)

# If any additional sources must be added, put those before this command.
apt-get update
apt-get install -y "${apt_packages[@]}"

# Executing unminimize does a lot, and in general prepares the image for user login.
yes | unminimize || { echo "Unminimize failed."; exit 1; }

# Now clear the apt cache, because we don't want to store it in the image.
rm -rf /var/lib/apt/lists/*
