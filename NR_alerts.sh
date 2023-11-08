#!/bin/bash
set -x

help(){
    printf "New Relic Synthetics Alert Management Script\n"
    printf "--------------------------------------------\n"
    printf "Usage: ./NR_alerts.sh <action> <X-Api-Key> <policy_id>\n\n"
    printf "Actions:\n"
    printf "  enable    : Enable Synthetics alerts for the specified policy.\n"
    printf "  disable   : Disable Synthetics alerts for the specified policy.\n\n"
    printf "Example: ./NR_alerts.sh enable 11111asfawvads 111\n"
    printf "         (Enables alerts using X-Api-Key '11111asfawvads' for policy_id '11111')\n\n"
}

if [ $# -eq 0 ]; then
    help
    exit 1
fi

if [ "$1" == "enable" ]; then
    enable_status="true"
elif [ "$1" == "disable" ]; then
    enable_status="false"
else
    help
    exit 1
fi

X_API_KEY="$2"  # Second argument is the X-Api-Key
policy_id="$3"  # Third argument is the policy_id

syn_li=$(curl -X GET 'https://api.newrelic.com/v2/alerts_synthetics_conditions.json' -H 'accept: application/json' -H "X-Api-Key:${X_API_KEY}" -G -d "policy_id=${policy_id}")
echo $syn_li

ids=$(echo $syn_li | jq '.synthetics_conditions[].id')
id_array=($ids)
monitor_ids=$(echo $syn_li | jq '.synthetics_conditions[].monitor_id')
monitor_ids_array=($monitor_ids)
names=$(echo $syn_li | jq '.synthetics_conditions[].name')
names_array=($names)

echo $id_array
echo $monitor_ids_array
echo $names_array

iterator=0
while [ $iterator -lt ${#id_array[@]} ]; do
    echo ${id_array[$iterator]}
    echo ${monitor_ids_array[$iterator]}

    json_data='{
        "synthetics_condition": {
            "name": '${names_array[$iterator]}',
            "monitor_id": '${monitor_ids_array[$iterator]}',
            "enabled": '$enable_status'
        }
    }'

    url="https://api.newrelic.com/v2/alerts_synthetics_conditions/${id_array[$iterator]}.json"
    curl -X PUT "$url" \
        -H 'accept: application/json' \
        -H "X-Api-Key:$X_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "${json_data}"

    echo $url
    echo $json_data

    iterator=$((iterator + 1))
done
