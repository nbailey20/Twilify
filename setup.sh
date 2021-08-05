#!/bin/bash

echo "Building Lambda zip files from sources..."
cd lambda/tmf-app-lambda/libraries
7z a -r ../tmf-app-lambda.zip .  > /dev/null 2>&1
cd ..
7z a tmf-app-lambda.zip *.py

cd ../tmf-reception-lambda
7z a tmf-reception-lambda.zip *.py  > /dev/null 2>&1
cd ../..

echo "Initializing and building application..."
terraform init  > /dev/null 2>&1
terraform plan  > /dev/null 2>&1
terraform apply -auto-approve

account=$(terraform output -raw account_sid)
phone=$(terraform output -raw number_sid)
url=$(terraform output -raw tmf-invoke-url)
token=$(terraform output -raw token)

echo "Integrating Twilio phone number messaging with AWS deployment..."
curl -s -XPOST https://api.twilio.com/2010-04-01/Accounts/$account/IncomingPhoneNumbers/$phone.json \
    --data-urlencode "SmsUrl=$url" \
    -u "$account:$token"

if [ $? -eq 0 ]
then
    echo "TMF application successfully deployed, text and say hello!"
else
    echo "Uh oh, something went wrong with TMF build..."
fi