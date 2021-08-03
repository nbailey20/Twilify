#!/bin/bash

cd lambda/tmf-app-lambda/libraries
7z a -r ../tmf-app-lambda.zip .
cd ..
7z a tmf-app-lambda.zip *.py

cd ../tmf-reception-lambda
7z a tmf-reception-lambda.zip *.py
cd ../..

terraform init
terraform plan
terraform apply -auto-approve

account=$(terraform output -raw account_sid)
phone=$(terraform output -raw number_sid)
url=$(terraform output -raw tmf-invoke-url)
token=$(terraform output -raw token)

curl -XPOST https://api.twilio.com/2010-04-01/Accounts/$account/IncomingPhoneNumbers/$phone.json \
    --data-urlencode "SmsUrl=$url" \
    -u "$account:$token"