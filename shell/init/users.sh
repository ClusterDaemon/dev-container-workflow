#!/bin/bash
mapfile -t groups < <(jq -c '.[]' <<<$GROUPS)
mapfile -t users < <(jq -c '.[]' <<<$USERS)

for group in ${groups[@]}; do
    groupName=$(jq -r '.groupName' <<<$group)
    gid=$(jq -r '.gid' <<<$group)
    
    if [[ -z $gid ]]; then
        addgroup "$groupName"
    else
        addgroup "$groupName" "$gid"
    fi
done

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

    sed -i "/^$userName:/ s|[^:]*|$hashedPassword|2" /etc/shadow
done
