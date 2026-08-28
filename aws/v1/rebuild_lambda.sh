#!/bin/bash

echo "Building twilify zip file from sources..."
cd lambda/twilify-app-lambda/libraries
rm -f ../twilify-app-lambda.zip > /dev/null 2>&1
7z a -r ../twilify-app-lambda.zip .  > /dev/null 2>&1
cd ..
7z a twilify-app-lambda.zip *.py > /dev/null 2>&1

echo "Building twilify reception zip file from sources..."
cd ../twilify-reception-lambda/libraries
rm -f ../twilify-reception-lambda.zip > /dev/null 2>&1
7z a -r ../twilify-reception-lambda.zip .  > /dev/null 2>&1
cd ..
7z a -r twilify-reception-lambda.zip ./helpers  > /dev/null 2>&1
7z a twilify-reception-lambda.zip *.py  > /dev/null 2>&1
cd ../..

terraform taint aws_s3_object.twilifyReceptionLambda
terraform taint aws_lambda_function.twilifyReceptionLambda
terraform taint time_sleep.wait_10_seconds1
terraform taint aws_lambda_permission.allow_anonymous_reception_invocation

# terraform taint aws_s3_object.twilifyAppLambda
# terraform taint aws_lambda_function.twilifyAppLambda
# terraform taint time_sleep.wait_10_seconds2