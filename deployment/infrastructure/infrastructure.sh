#!/bin/bash

printf "\nBegin Setup for AWS Infrastructure.\n"

function finish {
    rv=$?
    printf "\nSetup Completed with Error code ${rv}"
    popd
}

trap finish EXIT

current_directory=$(dirname $0)
pushd ${current_directory}

set -e

region=$1

echo "Creating S3 Bucket"
account=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://${account}-terraform-state --region ${region}

echo "Creating DynamoDB Table"
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1