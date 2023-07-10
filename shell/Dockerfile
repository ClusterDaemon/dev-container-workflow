FROM ubuntu:22.04

ARG cluster_version 
ENV cluster_version=$cluster_version 

# Install required applications and build user skeleton
COPY ./install.sh /install.sh
RUN /bin/bash /install.sh

# Expose the ttyd port
EXPOSE 7681

# Set ttyd as the entrypoint
ENTRYPOINT ["ttyd", "-p", "7681", "bash"]
