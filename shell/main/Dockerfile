FROM ubuntu:22.04

ARG cluster_version 
ENV cluster_version=$cluster_version 

# Install required applications and build user skeleton
COPY ./skel /etc/skel
COPY ./install.sh /install.sh
RUN /bin/bash /install.sh

# Give the system a user directory location which can be shadowed by a volume mount.
# This allows an init container to update the directory by sharing the volume.
RUN mkdir /users \
    && mv /etc/passwd /etc/group /etc/shadow /etc/gshadow /users \
    && ln -s /users/passwd /etc/passwd \
    && ln -s /users/group /etc/group \
    && ln -s /users/shadow /etc/shadow \
    && ln -s /users/gshadow /etc/gshadow

# Expose the ttyd port
EXPOSE 7681

# Set ttyd as the entrypoint, and protect the shell via login. Requires a user with a password.
ENTRYPOINT ["ttyd", "-p", "7681", "login"]
