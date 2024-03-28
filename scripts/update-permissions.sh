#!/usr/bin/env bash

connect_return=$(curl "https://edstem.org/api/challenges/$ED_CHALLENGE_ID/connect" \
    -X POST \
    -H "content-type: application/json" \
    -H "Authorization: $ED_API_TOKEN" \
    --data-raw "{\"user_id\":null,\"password\":\"\",\"i\":null}"
)
ticket=$(echo $connect_return | jq -r '.ticket')

runscript() {
    upload_dir="/home/websystems/"
    command="chmod -R o+x $upload_dir"
    read -r output
    read -r output

    echo "{\"type\":\"program_open\",\"data\":{\"id\":\"term-$$\",\"command\":\"bash --login\",\"pty_size\":{},\"start_if_stopped\":true}}"
    read -r output
    echo "$output" >&2
    read -r output
    read -r output

    echo "{\"type\":\"program_data\",\"data\":{\"id\":\"term-$$\",\"data\":\"$(echo $command | base64)\"}}"
    read -r output
    echo "$output" >&2

    echo "{\"type\":\"program_data\",\"data\":{\"id\":\"term-$$\",\"data\":\"$(echo "exit" | base64)\"}}"
    read -r output
    
    # kill websocat, even if the websocket doesn't get closed
    kill "$PPID"
}
export -f runscript

websocat "wss://sahara.au.edstem.org/connect/${ticket}" \
    --text \
    sh-c:'exec bash -c runscript'
wait