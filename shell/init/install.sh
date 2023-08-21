#!/bin/bash

################
# APPLICATIONS #
################
# Manifest of installed applications

apt_packages=(
    curl
    git
    jq
)

#
# See GIT section for applications installed via repositories.
#

# Set a single global version for asdf plugins.
# Does not handle dependencies. Comment with any dependency instructions.
declare -A asdf_plugins=(
    [kubectl]="latest"
    [krew]="latest"
)

# Install baseline kubectl plugins. These should be implementation agnostic, where exceptions to this must be justified.
# Like asdf, These plugins don't necessarily install dependencies. Where possible, install dependencies with asdf.
krew_plugins=(
    access-matrix
    cert-manager
    df-pv # Useful for getting statistics from extensions that do not use the shared persistence model
    exec-as # Useful for executing commands via persistent extensions
    foreach
    gadget # Must also be installed to the cluster, and needs kernel >=5.10: $ kubectl gadget deploy
    get-all
    kadalu # Required for default GlusterFS persistence model.
    kubescape 
    node-shell
    ns
    popeye # Anomoldy detection and cluster sanitation, as opposed to just reporting (which kubescape does well)
    ssh-jump
    stern
    sudo # Not Linux sudo - executes commands in K8s as system:masters (if possible)
    tree
    tunnel # Useful for tunneling resources from one cluster to the host cluster - not very useful for a single cluster.
    virt
    warp # Potentially "easy mode" extension with copied context
)

#######
# APT #
#######
# Most things depend on what we obtain via apt. Because of that, it's first.

# The apt cache can be expected to be out of date or empty.
# If any additional sources must be added, put those before this command.
apt-get update
apt-get install -y "${apt_packages[@]}"

# Now clear the apt cache, because we don't want to store it in the image.
rm -rf /var/lib/apt/lists/*

#######
# GIT #
#######
# Applications obtianed from git should be only a single ref, and retain the repository configuration.
git clone https://github.com/ClusterDaemon/vim.git --single-branch --branch "main" /etc/skel/.vim \
    || { echo "Cloning vim configuration repository failed."; exit 1; }
git -C /etc/skel/.vim submodule update --init --recursive \
    || { echo "Recursively cloning vim plugin repositories as submodules failed."; exit 1; }
cp /etc/skel/.vim/.vimrc /etc/skel/.vimrc

git clone https://github.com/ClusterDaemon/tmux.git --single-branch --branch "main" /etc/skel/.tmux \
    || { echo "Cloning tmux configuration repository failed."; exit 1; }
git -C /etc/skel/.tmux submodule update --init --recursive \
    || { echo "Recursively cloning tmux plugin repositories as submodules failed."; exit 1; }
cp /etc/skel/.tmux/tmux.conf /etc/skel/.tmux.conf

git clone https://github.com/asdf-vm/asdf.git --single-branch --branch "v0.12.0" /etc/skel/.asdf \
    || { echo "Cloning asdf application repository failed."; exit 1; }


#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
# Before setting up asdf and krew, we need to set the home directory to be the user skeleton, rather than /root.
HOME=/etc/skel
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

########
# ASDF #
########
. $HOME/.asdf/asdf.sh

# Set a single global version for asdf plugins.
for plugin in "${!asdf_plugins[@]}"; do
    asdf plugin add "$plugin"
    asdf install "$plugin" "${asdf_plugins[$plugin]}"
    asdf global "$plugin" "${asdf_plugins[$plugin]}"
done

########
# KREW #
########
# Add Krew to the current path
PATH=$HOME/.krew/bin:$PATH
# Refresh the plugin index
kubectl krew update

for plugin in "${krew_plugins[@]}"; do
    kubectl krew install "$plugin";
done
