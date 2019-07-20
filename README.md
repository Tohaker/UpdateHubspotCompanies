# UpdateHubspotCompanies
A collection of AWS Lambdas to continuously update a Hubspot account.

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

### Terraform

[TODO: Terraform setup script]

Ensure your AWS Credentials file has a user specified that has permissions to write to the S3 bucket and DynamoDB Table. More permissions are often needed, these are stored in [infrastructure/iam/terraform-role.role]

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
