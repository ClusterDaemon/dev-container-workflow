ARG LONGSHOREMAN_TAG="latest"
FROM longshoreman-shell:$LONGSHOREMAN_TAG as main

FROM ubuntu:22.04

ENV USERS='[{"userName":"user"}]'

COPY --from=main /etc/opt/users/* /etc/
COPY ./skel /etc/skel
COPY ./install.sh /install.sh
COPY ./users.sh /users.sh

RUN /bin/bash /install.sh

ENTRYPOINT ["/users.sh"]
