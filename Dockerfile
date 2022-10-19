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
    && curl -L https://go.dev/dl/go1.19.2.linux-amd64.tar.gz | tar -C /usr/local/ -xz 
COPY configs/sshd_config /etc/ssh/
COPY configs/skel /etc/skel
ENTRYPOINT [ "/usr/sbin/sshd", "-D" ]
