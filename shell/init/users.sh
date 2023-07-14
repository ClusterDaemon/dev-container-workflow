#!/bin/bash
# Creates POSIX users and groups according to string-serialized JSON input via $USERS and $GROUPS
# Copies identities to a directory specified via $USERS_DIR
# GROUPS: [{
#   groupName: string,
#   gid: number
# }]
# USERS: [{
#   userName: string,
#   primaryGroup: string,
#   uid: number,
#   gid: number,
#   additionalGroups: list(string),
#   hashedPassword: string
# }]
# Exit codes:
# 0: Ono
# 1: Warnings
# 2: Errors
exit_code=0
time=$(date +%s)
usersDir=${USERS_DIR:-/etc/opt/users/}
noHome=false

mapfile -t groups < <(jq -c '.[]' <<<$GROUPS)
mapfile -t users < <(jq -c '.[]' <<<$USERS)

if ! grep -qs /home /proc/mounts; then
    echo "Warning: No volume is mounted to /home, so user directories cannot be created or updated."
    exit_code=1
    noHome=true
fi

if grep -qs "$usersDir " /proc/mounts; then
    echo "Error: No volume is mounted to $usersDir. Identity export failed. Set \$USERS_DIR and mount a volume there."
    exit 2
fi

# Create groups
for group in ${groups[@]}; do
    groupName=$(jq -r '.groupName' <<<$group)
    gid=$(jq -r '.gid' <<<$group)
    
    if [[ -z $gid ]]; then
        addgroup "$groupName"
    else
        addgroup "$groupName" "$gid"
    fi
done

# Create users, build user directories if they do not already exist, sync changes from /etc/skel
for user in ${users[@]}; do
    userName=$(jq -r '.userName' <<<$user)
    uid=$(jq -r '.uid' <<<$user)
    primaryGroup=$(jq -r '.gid' <<<$user)
    gid=$(jq -r '.gid' <<<$user)
    hashedPassword=$(jq -r '.hashedPassword' <<<$user)
    mapfile -t additionalGroups < <(jq -r '.additionalGroups.[]' <<<$user)

    adduserArgs=()
    (( test -n $uid )) && args+=( "--uid $uid" )
    (( test -n $gid )) && args+=( "--gid $gid" )
    (( test $primaryGroup != $userName )) && args+=( "--ingroup $primaryGroup" )
    (( test ${#additionalGroups[@]} > 0 )) && args+=( "--add-extra-groups ${additionalGroups[@]}" )
    args+=( "--disabled-password" )
    args+=( --gecos x )

    adduser ${adduserArgs[@]}

    # Place hashed passwords directly into /etc/shadow. The default empty password results in passwordless login.
    echo "Updating hashedPassword in /etc/shadow for $userName."
    sed -i "/^$userName:/ s|[^:]*|$hashedPassword|2" /etc/shadow || {
        echo "Error: Cannot update hashedPassword in /etc/shadow for $userName. Identity creation failed."
        exit 2
    }

    if [[ ! $noHome ]]; then
        echo "Updating ${userName}'s home directory with changes to the skeleton."
        echo "Files which are newer in the skeleton will overwrite existing files in the home directory."
        echo "The following overwritten files are recorded in ~/skel-updates-$time"
        cp -pruv -B "~bak-$time" /etc/skel/* /home/"$userName"/ | grep '\->' | tee /home/"$userName"/skel-updates-$time || {
            echo "Warning: Cannot update ${userName}'s home directory with changes to built-in applications and config."
            exit_code=1
        }
    fi
done

# Copy resulting user information into a volume shared with a longshoreman-shell instance.
cp /etc/passwd /etc/group /etc/shadow /etc/gshadow "$usersDir" || {
    echo "Copying system identities to shared users volume failed. Identity export failed."
    exit 2
}

exit $exit_code
