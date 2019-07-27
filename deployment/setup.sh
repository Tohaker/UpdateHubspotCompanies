#!/bin/bash

printf "\nBegin Setup for AWS Lambdas.\n"

function finish {
    rv=$?
    printf "\nSetup Completed with Error code ${rv}\n"
}

trap finish EXIT

current_directory=$(dirname $0)
pushd ${current_directory}

set -e

ftp_username=$1
ftp_password=$2
client_id=$3
client_secret=$4

echo "Packaging Applications:"

echo "Copying lambda applications..."
cp -a ../lambdas/. ./packages

echo "Downloading latest python packages..."

for directory in ./packages/*/
do 
    ls -l -d ${directory}
    if test -f "${directory}/requirements.txt"; then
        python3 -m venv ${directory}/venv
        source ${directory}/venv/bin/activate
        pip3 install -r ${directory}/requirements.txt
    fi
done

echo "Creating ZIP file packages..."
for directory in ./packages/*/
do 
    if [ -d "${directory}/venv" ]; then
        cp -a ${directory}/venv/lib/python*/site-packages/. ${directory}
        rm -rf ${directory}/venv
        rm ${directory}/requirements.txt
    fi
    zip -r ${directory}/function.zip ${directory}
done

echo "Done creating function packages!"

echo "Moving to Terraform folder."
cd terraform

echo "Initialising Terraform."
terraform init \
    -backend=true \
    -backend-config="access_key=${AWS_ACCESS_KEY}" \
    -backend-config="secret_key=${AWS_SECRET_KEY}"

echo "Planning Terraform."
terraform plan \
    -var="ftp_username=${ftp_username}" \
    -var="ftp_password=${ftp_password}" \
    -var="client_id=${client_id}" \
    -var="client_secret=${client_secret}" \
    -out=output.tfplan

echo "Applying Terraform."
terraform apply \
    -auto-approve \
    "output.tfplan"
    
