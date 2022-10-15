FROM ubuntu:22.04
# Package installations
RUN apt update
RUN apt install -y sudo ssh vim tmux curl docker.io git jq zip python3
## AWS
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip
RUN ./aws/install && aws --version
## Go
RUN curl -L https://golang.org/dl/go1.19.2.linux-amd64.tar.gz | tar -C /usr/local -xz
## Kubectl
RUN curl --output-dir /usr/bin/ -LO https://dl.k8s.io/release/v1.25.0/bin/linux/amd64/kubectl && chmod +x /usr/bin/kubectl && curl -LO https://dl.k8s.io/v1.25.0/bin/linux/amd64/kubectl.sha256 && echo "$(cat kubectl.sha256)  /usr/bin/kubectl" | sha256sum --check
## Kustomize
RUN curl -LO https://github.com/mozilla/sops/releases/download/v3.7.3/sops_3.7.3_amd64.deb && dpkg -i sops_3.7.3_amd64.deb && rm sops_3.7.3_amd64.deb
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
## Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
## User environment setup (will be done via Kube instead)
#RUN groupadd $USERNAME && useradd --create-home --shell /bin/bash -g $USERNAME -G sudo,docker $USERNAME
#USER $USERNAME
### SSH
#RUN mkdir ~/.ssh
### Git
#COPY configs/gitconfig /home/dhay/.gitconfig
### VIM
#RUN git clone https://github.com/ClusterDaemon/vim.git --single-branch --branch main ~/.vim && cp ~/.vim/.vimrc ~/
### Go
#RUN echo 'export PATH="/usr/local/go/bin:$PATH"' >> /home/dhay/.bashrc
### Helm
#RUN helm repo add bitnami https://charts.bitnami.com/bitnami
## Runtime setup
#WORKDIR /home/$USERNAME
#ENTRYPOINT tmux
