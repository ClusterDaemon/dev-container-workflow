#!/bin/bash
# Initializes a POSIX user according to string-serialized JSON input
# Copies identities to a directory specified via $USERS_DIR
# Input JSON follows this schema: {
#   userName: string,
#   groupName: string,
#   uid: number,
#   gid: number,
#   hashedPassword: string
# }
# Exit codes:
# 0: Ono
# 1: Warnings
# 2: Errors
exit_code=0
time=$(date +%s)
users_dir=${USERS_DIR:-/etc/opt/users/}
no_home=false
default_uid=1000

if ! grep -qs /home /proc/mounts; then
    echo "Warning: No volume is mounted to /home, so user directories cannot be created or updated."
    exit_code=1
    no_home=true
fi

if grep -qs "$users_dir " /proc/mounts; then
    echo "Error: No volume is mounted to $users_dir. Identity export failed! Set \$USERS_DIR and mount a volume there."
    exit 2
fi

# Create an associative array using the input JSON, so we can access values within the shell.
declare -A user

while IFS="=" read -r key value; do
    user["$key"]="$value"
done < <(jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' <<<$1)

# Validate the supplied JSON against schema
valid_keys=("userName" "uid" "gid" "groupName" "hashedPassword")
required_keys=("userName")
for key in ${valid_keys[@]}; do
    if [[ ! -v user[$key] && ${required_keys[*]} =~ $key ]]; then
        echo "Error: Invalid JSON input! Key $key is required, and has no default."
        exit 2
    elif [[ ! -v user[key] ]]; then
        echo "Warning: Invalid JSON input! Key $key is not expected, and will be ignored."
        exit_code=1
    fi
done

# Build arguments to adduser
args=()
if [[ -n ${user[uid]} ]]; then
    args+=( "--uid ${user[uid]}" )
else
    args+=( "--uid $default_uid" )
fi

if [[ -n ${user[gid]} ]]; then
    args+=( "--gid ${user[gid]}" )
else
    args+=( "--gid $default_uid" )
fi

(( test ${user[groupName]} != ${user[userName]} )) && args+=( "--ingroup ${user[groupName]}" )

args+=( "--disabled-password" )
args+=( --gecos x )

# Execute adduser actual
adduser ${args[@]} || {
    echo "Error: failed to add user ${user[userName]}!"
    exit 2
}

# Place hashed passwords directly into /etc/shadow. The default empty password results in passwordless login.
sed -i "/^${user[userName]}:/ s|[^:]*|${user[hashedPassword]}|2" /etc/shadow || {
    echo "Error: Cannot update hashedPassword in /etc/shadow for ${user[userName]}. Identity creation failed!"
    exit 2
}

if [[ ! $no_home ]]; then
    echo "Updating ${user[userName]}'s home directory with changes to the skeleton."
    echo "Files which are newer in the skeleton will overwrite existing files in the home directory."
    echo "The following overwritten files are recorded in ~/skel-updates-$time"
    cp -pruv -B "~bak-$time" /etc/skel/* /home/"${user[userName]}"/ | grep '\->' | tee /home/"${user[userName]}"/skel-updates-$time || {
        echo "Warning: Cannot update ${user[userName]}'s home directory with changes to built-in applications and config."
        exit_code=1
    }
fi

# Copy resulting user information into a volume shared with a longshoreman-shell instance.
cp /etc/passwd /etc/group /etc/shadow /etc/gshadow "$users_dir" || {
    echo "Copying system identities to shared users volume failed. Identity export failed!"
    exit 2
}

exit $exit_code
