#!/bin/bash

# echo "Building twilify zip file from sources..."
# cd lambda/twilify-app-lambda/libraries
# rm -f ../twilify-app-lambda.zip > /dev/null 2>&1
# 7z a -r ../twilify-app-lambda.zip .  > /dev/null 2>&1
# cd ..
# 7z a twilify-app-lambda.zip *.py > /dev/null 2>&1

# echo "Building twilify reception zip file from sources..."
# cd ../twilify-reception-lambda/libraries
# rm -f ../twilify-reception-lambda.zip > /dev/null 2>&1
# 7z a -r ../twilify-reception-lambda.zip .  > /dev/null 2>&1
# cd ..
# 7z a twilify-reception-lambda.zip *.py  > /dev/null 2>&1
# cd ../..

## Retrieve Spotify refresh token and append to tfvars file
spotify_client_id=$(grep 'spotify_client_id' terraform.auto.tfvars | awk '{ print $3 }' | tr -d \")
spotify_client_secret=$(grep 'spotify_client_secret' terraform.auto.tfvars | awk '{ print $3 }' | tr -d \")
spotify_refresh_token=$(python get_refresh_token.py $spotify_client_id $spotify_client_secret)
sed -i "/spotify_client_secret =/a spotify_refresh_token = \"$spotify_refresh_token\"" terraform.auto.tfvars

echo "Initializing and building application..."
terraform init  > /dev/null 2>&1
terraform plan  > /dev/null 2>&1
terraform apply -auto-approve

account=$(terraform output -raw account_sid)
phone=$(terraform output -raw number_sid)
url=$(terraform output -raw twilify-invoke-url)
token=$(terraform output -raw token)

echo
echo
echo "Integrating Twilio phone number messaging with AWS-based Twilify deployment..."
curl -s -XPOST https://api.twilio.com/2010-04-01/Accounts/$account/IncomingPhoneNumbers/$phone.json \
    --data-urlencode "SmsUrl=$url" \
    -u "$account:$token" > /dev/null 2>&1

if [ $? -eq 0 ]
then
    echo
    echo "Twilify application successfully deployed, text and say hello!"
else
    echo "Uh oh, something went wrong with Twilify build..."
fi