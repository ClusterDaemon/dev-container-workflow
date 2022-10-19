FROM ubuntu:22.04

ENV PATH="/usr/local/go/bin:$PATH" \
    KSOPS_DIR="/ksops" \
    VIM_DIR="/vim" \
    TMUX_DIR="/tmux"
RUN apt update \
    && apt install -y \
        bash \
        sudo \
        openssh-server \
        vim \
        tmux \
        curl \
        docker \
        git \
        jq \
        zip \
        gpg \
        python3 \
        python3-pip \
    ## Curl-gotten utils \
    && curl -LO "https://github.com/mozilla/sops/releases/download/v3.7.3/sops_3.7.3_amd64.deb" \
    && dpkg -i sops_3.7.3_amd64.deb \
    && rm sops_3.7.3_amd64.deb \
    && curl -Ls "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && curl "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | bash \
    && curl --output-dir /tmp -LO "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    && unzip -d /tmp/ /tmp/awscli-exe-linux-x86_64.zip \
    && /tmp/aws/install \
    && aws --version \
    && rm -rf /tmp/aws/ /tmp/awscli-exe-linux-x86_64.zip \
    && curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash \
    && curl -L https://go.dev/dl/go1.19.2.linux-amd64.tar.gz | tar -C /usr/local/ -xz 
COPY configs/sshd_config /etc/ssh/
COPY configs/skel /etc/skel
ENTRYPOINT [ "/usr/sbin/sshd", "-D" ]
