#!/bin/bash

echo "Building tmf zip file from sources..."
cd functions/tmf-app
rm -f ./tmf-app-function.zip > /dev/null 2>&1
7z a -r ./tmf-app-function.zip .  > /dev/null 2>&1

echo "Building tmf reception zip file from sources..."
cd ../tmf-reception
rm -f ../tmf-reception-function.zip > /dev/null 2>&1
7z a -r ./tmf-reception-function.zip .  > /dev/null 2>&1
cd ../..

echo "Initializing, planning, and building application..."
sleep 4
terraform init
terraform plan
terraform apply -auto-approve

account=$(terraform output -raw account_sid)
phone=$(terraform output -raw number_sid)
url=$(terraform output -raw tmf-invoke-url)
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
    echo "TMF application successfully deployed, text and say hello!"
else
    echo "Uh oh, something went wrong with TMF build..."
fi