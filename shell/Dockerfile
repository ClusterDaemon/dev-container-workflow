FROM ubuntu:22.04

# Install required packages
RUN apt update \
    && apt install -y \
        curl \
        openssl \
        libwebsockets-dev \
        libreadline-dev \
        dialog \
        man \
        ttyd \
        tmux \
        vim \
        git \
        gh \
    && yes | unminimize

# Expose the ttyd port
EXPOSE 7681

# Set ttyd as the entrypoint
ENTRYPOINT ["ttyd", "-p", "7681", "bash"]
