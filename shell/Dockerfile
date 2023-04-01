FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    bash \
    openssl \
    libwebsockets \
    json-c \
    ttyd \
    tmux \
    vim \
    curl \
    ca-certificates

# Expose the ttyd port
EXPOSE 7681

# Set ttyd as the entrypoint
ENTRYPOINT ["ttyd", "-p", "7681", "bash"]
