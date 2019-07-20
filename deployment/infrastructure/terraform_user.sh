#!/bin/bash

printf "\nBegin Setup for Terraform Deploy User.\n"

function finish {
    rv=$?
    printf "\nSetup Completed with Error code ${rv}"
    popd
}

trap finish EXIT

current_directory=$(dirname $0)
pushd ${current_directory}

set -e

username=$1

echo "Creating User."
user_arn=$(aws iam create-user --user-name ${username} --query User.Arn --output text)

echo "Creating Policies."
terraform_policy_arn=$(aws iam create-policy --policy-name TerraformApply --policy-document file://terraform_policy.json --query Policy.Arn --output text)
s3_policy_arn=$(aws iam create-policy --policy-name S3TerraformStateBackend  --policy-document file://s3_policy.json --query Policy.Arn --output text)
dynamodb_policy_arn=$(aws iam create-policy --policy-name DynamoDBTerraformStateLock   --policy-document file://dynamodb_policy.json --query Policy.Arn --output text)

echo "Attaching Policies."
aws iam attach-user-policy --policy-arn ${terraform_policy_arn} --user-name ${username}
aws iam attach-user-policy --policy-arn ${s3_policy_arn} --user-name ${username}
aws iam attach-user-policy --policy-arn ${dynamodb_policy_arn} --user-name ${username}

