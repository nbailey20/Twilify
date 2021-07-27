#!/bin/bash

zip -r tmf-app-lambda/tmf-app-lambda.zip tmf-app-lambda/libraries/
zip -g tmf-app-lambda/tmf-app-lambda.zip tmf-app-lambda/*.py

zip tmf-reception-lambda/tmf-reception-lambda.zip tmf-reception-lambda/*.py

terraform init
terraform plan
