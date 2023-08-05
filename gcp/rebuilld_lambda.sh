#!/bin/bash

echo "Building Twilify zip file from sources..."
cd functions/twilify-app
rm -f ./twilify-app-function.zip > /dev/null 2>&1
7z a -r ./twilify-app-function.zip .  > /dev/null 2>&1

echo "Building Twilify reception zip file from sources..."
cd ../twilify-reception
rm -f ../twilify-reception-function.zip > /dev/null 2>&1
7z a -r ./twilify-reception-function.zip .  > /dev/null 2>&1
cd ../..

