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
7z a twilify-reception-lambda.zip *.py  > /dev/null 2>&1
cd ../..
