#!/bin/bash

usage() { echo "Usage: $0 aws|gcp"; exit 1; }

add_spotify_refresh_token() {
    ## generate refresh token and append to tfvars file
    spotify_client_id=$(grep 'spotify_client_id' terraform.auto.tfvars | awk '{ print $3 }' | tr -d \")
    spotify_client_secret=$(grep 'spotify_client_secret' terraform.auto.tfvars | awk '{ print $3 }' | tr -d \")
    spotify_refresh_token=$(python get_refresh_token.py $spotify_client_id $spotify_client_secret)
    sed -i "/spotify_client_secret =/a spotify_refresh_token = \"$spotify_refresh_token\"" terraform.auto.tfvars
}

execute_terraform() {
    echo "Initializing and building application..."
    sleep 3
    terraform init  > /dev/null 2>&1
    terraform plan  > /dev/null 2>&1
    terraform apply -auto-approve
}

configure_twilio() {
    ## Setup Twilio webhook to make POST request to Twilify API when texted
    account=$(terraform output -raw account_sid)
    sid=$(terraform output -raw number_sid)
    url=$(terraform output -raw twilify-invoke-url)
    token=$(terraform output -raw token)
    number=$(terraform output -raw twilio-number)

    echo
    echo
    echo "Integrating Twilio phone number messaging with Twilify deployment..."
    curl -s -XPOST https://api.twilio.com/2010-04-01/Accounts/$account/IncomingPhoneNumbers/$sid.json \
        --data-urlencode "SmsUrl=$url" \
        -u "$account:$token" > /dev/null 2>&1
}

###################################################
## Start Main Code Block
###################################################
if [ $# -ne 1 ]; then
    usage
fi

if [ $1 != "aws" ] && [ $1 != "gcp" ]; then
    usage
fi

add_spotify_refresh_token
if [ $? -ne 0 ]; then
    echo "Uh oh, install script failed retrieving Spotify refresh token or saving to tfvars file, exiting."
    exit 2
fi

cp terraform.auto.tfvars ../$1/
cd ../$1
execute_terraform
configure_twilio

if [ $? -eq 0 ]; then
    echo
    echo "Twilify application successfully deployed, text $number and say hello!"
else
    echo "Uh oh, something went wrong with Twilify build..."
    exit 2
fi