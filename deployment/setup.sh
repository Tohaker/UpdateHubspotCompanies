#!/bin/bash

printf "\nBegin Setup for AWS Lambdas.\n"

function finish {
    rv=$?
    printf "\nSetup Completed with Error code ${rv}"
    popd
}

trap finish EXIT

current_directory=$(dirname $0)
pushd ${current_directory}

set -e

ftp_username=$1
ftp_password=$2
client_id=$3

echo "Packaging Applications:"

echo "Copying lambda applications..."
cp -a ../lambdas/. ./packages

echo "Downloading latest python packages..."
for directory in ./packages/*/
do 
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

echo "Tidying up..."
shopt -s extglob
for directory in ./packages/*/
do 
    pushd ${directory}
    rm -rv !(*.zip)
    rm -rf .*
    find -mindepth 1 -maxdepth 1 -type d -exec rm -r {} \
    popd
done

echo "Done creating function packages!"

echo "Initialising Terraform."
terraform init

echo "Planning Terraform."
terraform plan \
    -var "ftp_username=${ftp_username}" \
    -var "ftp_password=${ftp_password}" \
    -var "client_id=${client_id}" \
    -out=output.tfplan

echo "Review Terraform plan then press enter to continue."
terraform apply \
    output.tfplan \
    -auto-approve
