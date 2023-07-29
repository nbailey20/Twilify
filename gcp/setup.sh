#!/bin/bash

echo "Building twilify zip file from sources..."
cd functions/twilify-app
rm -f ./twilify-app-function.zip > /dev/null 2>&1
7z a -r ./twilify-app-function.zip .  > /dev/null 2>&1

echo "Building twilify reception zip file from sources..."
cd ../twilify-reception
rm -f ../twilify-reception-function.zip > /dev/null 2>&1
7z a -r ./twilify-reception-function.zip .  > /dev/null 2>&1
cd ../..

echo "Initializing, planning, and building application..."
sleep 4
terraform init
terraform plan
terraform apply -auto-approve

account=$(terraform output -raw account_sid)
phone=$(terraform output -raw number_sid)
url=$(terraform output -raw twilify-invoke-url)
token=$(terraform output -raw token)

echo
echo
echo "Integrating Twilio phone number messaging with AWS deployment..."
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