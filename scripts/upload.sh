#!/bin/sh
site_path=$(readlink -f ./_site/)
site_path_length=${#site_path}

for file_path in $(find $site_path)
do
    if [ $site_path != $file_path ]
    then
        dir=$(dirname $file_path)
        
        relative_dir=$(echo $dir | cut -c $(($site_path_length+1))-)
        echo $relative_dir
        upload_return=$(curl "https://edstem.org/api/workspaces/$ED_WORKSPACE_ID/upload" \
        -X POST \
        -H "content-type: application/json" \
        -H "Authorization: $ED_API_TOKEN" \
        --data-raw "{\"wid\":\"$ED_WORKSPACE_ID\",\"path\":\"/home${relative_dir}/dummy\"}")

        ticket=$(echo $upload_return | jq -r '.ticket')

        curl "https://sahara.au.edstem.org/upload/${ticket}" \
        -X POST \
        -F upload=@$file_path \
          > /dev/null
    fi
done