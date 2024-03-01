#!/bin/sh

site_path="./_site/"
upload_dir="/home/"

abs_site_path=$(readlink -f $site_path)
abs_site_path_length=${#abs_site_path}

for file_path in $(find $abs_site_path -type f)
do
    if [ $abs_site_path != $file_path ]
    then
        dir=$(dirname $file_path)
        relative_dir=$(echo $dir | cut -c $(($abs_site_path_length+1))-)
        dest_dir=$(readlink -m $upload_dir/${relative_dir})
        dummy_path="$dest_dir/dummy"
        upload_return=$(curl "https://edstem.org/api/workspaces/$ED_WORKSPACE_ID/upload" \
            -X POST \
            -H "content-type: application/json" \
            -H "Authorization: $ED_API_TOKEN" \
            --data-raw "{\"wid\":\"$ED_WORKSPACE_ID\",\"path\":\"$dummy_path\"}")

        ticket=$(echo $upload_return | jq -r '.ticket')

        curl "https://sahara.au.edstem.org/upload/${ticket}" \
            -X POST \
            -F upload=@$file_path \
            > /dev/null

        relative_file=$(echo $file_path | cut -c $(($abs_site_path_length+1))-)
        dest_file=$(readlink -m $upload_dir/${relative_file})

        echo "Uploaded $file_path to $dest_file"
    fi
done