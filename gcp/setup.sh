#!/bin/bash

# echo "Building Twilify zip file from sources..."
# cd functions/twilify-app
# rm -f ./twilify-app-function.zip > /dev/null 2>&1
# 7z a -r ./twilify-app-function.zip .  > /dev/null 2>&1

# echo "Building Twilify reception zip file from sources..."
# cd ../twilify-reception
# rm -f ../twilify-reception-function.zip > /dev/null 2>&1
# 7z a -r ./twilify-reception-function.zip .  > /dev/null 2>&1
# cd ../..

echo "Initializing, planning, and applying Terraform build for Twilify..."
sleep 3
terraform init
terraform plan
terraform apply -auto-approve

account=$(terraform output -raw account_sid)
phone=$(terraform output -raw number_sid)
url=$(terraform output -raw twilify-invoke-url)
token=$(terraform output -raw token)

echo
echo
echo "Integrating Twilio phone number messaging with GCP-based Twilify deployment..."
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