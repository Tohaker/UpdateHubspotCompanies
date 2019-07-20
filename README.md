# UpdateHubspotCompanies
A collection of AWS Lambdas to continuously update a Hubspot account.

## Project Structure
For the setup script to work correctly, lambdas must follow this folder structure:
```
lambdas
├── lambda1
│   ├── main.py
│   └── requirements.txt
└── lambda2
    ├── main.py
    └── requirements.txt
```


## Requirements

* AWS CLI already configured with Administrator permission
* [Terraform installed](https://terraform.io)
* [Python 3 installed](https://www.python.org/downloads/)
* [Docker installed](https://www.docker.com/community-edition)

## Setup process

### Local development

**Invoking function locally using a local sample payload**

```bash
sam local invoke DaisyCustomerUpload --event event.json
```

**Invoking function locally through local API Gateway**

```bash
sam local start-api
```

## Deployment

Deployment is carried out using [Terraform](terraform.io).
Running the [`setup.sh`](deployment/setup.sh) script with the following parameters will build the project according to a strict directory layout.
```
./setup.sh <ftp_username> <ftp_password>
```
e.g.
```
./setup.sh OVR90120 fqfgsflusgfkqwg
```

### Terraform

Ensure your AWS Credentials file has a user specified that has permissions to write to the S3 bucket and DynamoDB Table. More permissions are often needed, these are stored in [deployment/iam/terraform-role.role]

Navigate to the `terraform` folder and initialise Terraform
```
terraform init
```

Plan the Terraform to see what will be created.
```
terraform plan
```

Apply the Terraform to create the infrastructure.
```
terraform apply
```
