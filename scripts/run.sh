#!/usr/bin/env bash

connect_return=$(curl "https://edstem.org/api/challenges/$ED_CHALLENGE_ID/connect" \
    -X POST \
    -H "content-type: application/json" \
    -H "Authorization: $ED_API_TOKEN" \
    --data-raw "{\"user_id\":null,\"password\":\"\",\"i\":null}" 2> /dev/null
)
ticket=$(echo $connect_return | jq -r '.ticket')

tmpdir=
cleanup () {
  trap - EXIT
  if [ -n "$tmpdir" ] ; then rm -rf "$tmpdir"; fi
  if [ -n "$1" ]; then trap - $1; kill -$1 $$; fi
}
tmpdir=$(mktemp -d)
trap 'cleanup' EXIT
trap 'cleanup HUP' HUP
trap 'cleanup TERM' TERM
trap 'cleanup INT' INT

mkfifo "$tmpdir/hashpipe"

socketscript() {
    read -r
    read -r
    echo "Started Session" >&2

    echo "{\"type\":\"commit\",\"data\":{\"id\":\"|$(date +%s%N | cut -b1-13)\"}}"
    read -r output
    echo $output | jq -r '.data.commit.hash' > "$1"
}

socketscriptstring=$(declare -f socketscript)

hash=$(
    websocat "wss://sahara.au.edstem.org/connect/${ticket}" \
        --text \
        --exit-on-eof \
        sh-c:"exec bash -c '$socketscriptstring; socketscript $tmpdir/hashpipe'" &
        cat "$tmpdir/hashpipe"
)

run_return=$(
    curl "https://edstem.org/api/challenges/$ED_CHALLENGE_ID/run" \
        -X POST \
        -H "content-type: application/json" \
        -H "Authorization: $ED_API_TOKEN" \
        --data-raw "{\"pty_size\":{\"cols\":999,\"rows\":999},\"hash\":\"$hash\",\"command\":\"\",\"dump_files\":true,\"user_id\":null,\"password\":\"\",\"i\":null,\"is_check\":true}" 2> /dev/null
)

run_ticket=$(echo $run_return | jq -r '.ticket')

mkfifo "$tmpdir/endpipe"

cat "$tmpdir/endpipe" |
websocat "wss://sahara.au.edstem.org/run?ticket=${run_ticket}" --text --exit-on-eof |
    while read line; do
        type=$(echo $line | jq -r '.type')
        if [ "$type" == "run_exit" ]; then 
            echo > $tmpdir/endpipe
        elif [ "$type" == "run_frame" ]; then
            echo $line | jq -r '.data.data' | base64 -di
        fi;
    done;