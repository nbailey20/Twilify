#!/bin/bash

cd lambda/tmf-app-lambda/libraries
zip -r ../tmf-app-lambda.zip .
cd ..
zip -g tmf-app-lambda.zip *.py

cd ../tmf-reception-lambda
zip tmf-reception-lambda.zip *.py
cd ../..

terraform init
terraform plan
