ARG LONGSHOREMAN_TAG="latest"
FROM longshoreman-shell:$LONGSHOREMAN_TAG as main

FROM ubuntu:22.04

COPY --from=main /users/* /users/
COPY ./users.sh /users.sh
RUN rm -f /etc/passwd /etc/group /etc/shadow /etc/gshadow \
    && ln -s /users/passwd /etc/passwd \
    && ln -s /users/group /etc/group \
    && ln -s /users/shadow /etc/shadow \
    && ln -s /users/gshadow /etc/gshadow \
    && apt-get update \
    && apt-get install -y jq

ENTRYPOINT ["/users.sh"]
# Entrypint accepts no arguments, and uses only environment.
# The environment expects a series of string-serialized JSON, for which the schema is:
# $GROUPS: [
#   groupName: string,
#   gid: number
# ]
# $USERS: [
#   userName: string,
#   primaryGroup: string,
#   uid: number,
#   gid: number,
#   additionalGroups: list(string),
#   hashedPassword: string
# ]
