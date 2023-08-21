FROM ubuntu:22.04

# Install required applications and build user skeleton
COPY ./install.sh /install.sh
RUN /bin/bash /install.sh

# Give the system a user directory location which can be shadowed by a volume mount.
# This allows an init container to define the directory by sharing a mounted volume.
RUN mkdir /etc/opt/users \
    && mv /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/opt/users \
    && ln -s /etc/opt/users/passwd /etc/passwd \
    && ln -s /etc/opt/users/group /etc/group \
    && ln -s /etc/opt/users/shadow /etc/shadow \
    && ln -s /etc/opt/users/gshadow /etc/gshadow

# Expose the ttyd port
EXPOSE 7681

# Set ttyd as the entrypoint, and protect the shell via login. Requires allowing a user to log in.
ENTRYPOINT ["ttyd", "-p", "7681", "login"]
