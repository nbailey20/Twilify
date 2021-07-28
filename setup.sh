#!/bin/bash

cd lambda/tmf-app-lambda/libraries
7z a -r ../tmf-app-lambda.zip .
cd ..
7z a tmf-app-lambda.zip *.py

cd ../tmf-reception-lambda
7z a tmf-reception-lambda.zip *.py
cd ../..

#terraform init
#terraform plan
