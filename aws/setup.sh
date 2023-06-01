#!/bin/bash

echo "Building tmf zip file from sources..."
cd lambda/tmf-app-lambda/libraries
rm -f ../tmf-app-lambda.zip > /dev/null 2>&1
7z a -r ../tmf-app-lambda.zip .  > /dev/null 2>&1
cd ..
7z a tmf-app-lambda.zip *.py > /dev/null 2>&1

echo "Building tmf reception zip file from sources..."
cd ../tmf-reception-lambda/libraries
rm -f ../tmf-reception-lambda.zip > /dev/null 2>&1
7z a -r ../tmf-reception-lambda.zip .  > /dev/null 2>&1
cd ..
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