# M.A.L.T

**M**icroservices on **A**WS **L**ambda using **T**erraform 

A module built in terraform to make deploying a microservice to AWS lambda easier.

## Usage

1. Setup your environment variables in a `.tfvars` file
2. Setup your `backend.tf` file, something like the following, assuming you use AWS S3 backend

```
terraform {
    backend "s3" {
        region = "eu-west-2"
        bucket = "terraform-state"
        key = "myCoolMicroservice.tfstate"
        dynamodb_table = "terraform_state_lock"
    }
}
```

3. Create a `main.tf` file and configure the module with your microservice
4. Run `terraform init`
5. Run `terraform plan`
6. Run `terraform apply`

## Environment details

Each enviroment you use this module in must use a different backend. At the time of writing this is only
possible by editing your backend file as dynamic variables are not supported in that file by terraform.

It is best to change this backend file in your piplines just before deployment to that environment using `sed`

Here is the code to modify the file, as you can see this changes the tfstate name in your backend to append
the environment name.

```shell
sed -i 's/\.tfstate/-prod\.tfstate/g' backend.tf
```

## Example Configuration

```terraform
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.69.0"
        }
        archive = {
            source = "hashicorp/archive"
            version = "~> 2.2.0"
        }
    }
}

provider "aws" {
    region = "eu-west-2"
}

locals {
    ms_name = "myCoolMicroservice"
    env_ms_name = join(
        "",
        [var.MS_ENV, title(local.ms_name)]
    )
}

module "malt" {
    source = "github.com/tristanbettany/MALT"

    ms_env = var.MS_ENV
    ms_name = local.ms_name
    env_ms_name = local.env_ms_name
    aws_account_id = var.AWS_ACCOUNT_ID

    # Lambda Functions
    functions = {
        "${local.env_ms_name}ExampleAction" = {
            runtime = "provided.al2"
            handler = "Handlers/example-action-handler.something"
            role = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:role/myRoleToApplyToLambdas"
            timeout = 28
            layers = [
                var.language_layer, # ARN pointing to the layers you wish to use
            ]
            security_group_ids = [
                "sg-1337", # Security groups to apply to the lambda VPC
            ]
            subnet_ids = [
                "subnet-1337", # Subnets to apply to the lambda VPC
            ]
            env_vars = {
                ENV_VAR_1 = var.ENV_VAR_1
                ENV_VAR_2 = var.ENV_VAR_2
            }
        }
    }

    # The below config is for the API gateway
  
    use_api_gateway = true

    # Resources positioned at segment 1 of the url
    segment_one_resources = {
        exampleCollection = {
            path_part = "example"
        }
    }

    # Resources positioned at segment 2 of the url
    segment_two_resources = {
        "exampleAction" = {
            path_part = "{id}"
            parent_resource = "exampleCollection" # Which segment 1 resource this belongs to  
        }
    }
  
    # For longer urls use segment_three_resources and segment_four_resources

    # Actions attached to a resource at segment 2 of the url which link to a lambda function
    actions = {
        # This root action is not needed but if you define it as having a root resource and a segment of zero
        # it will automatically attach to the root rather than looking for its resource in any of the other segment resource definitions
        root = {
          method = "GET"
          api_key_required = true
          auth = "NONE"
          function = "${local.env_ms_name}ExampleAction" # you can map more than 1 action to the same function
          segment = 0
          full_path = "" # this is the root so has no path
          resource = "root"
          integration_method = "POST"
          integration_type = "AWS_PROXY"
        }
        exampleAction = {
            method = "GET"
            api_key_required = true
            auth = "NONE"
            function = "${local.env_ms_name}ExampleAction"
            segment = 2 # Which segment is the final resource of the url of the action  
            full_path = "example/{id}" # the full path to the action, without a leading forward slash
            resource = "exampleAction"
            integration_method = "POST"
            integration_type = "AWS_PROXY"
        }
    }
    
    # Cors configuration for specific resources
    # Creates OPTIONS methods with the headers needed to make cors not get in your way
    cors = {
        exampleActionCors = {
            segment = 2
            resource = "exampleAction"
        }
    }
  
    domain_name = "myapp.stage.domain.tld"
    domain_zone_id = "XXXXXXXXXXXX" # This id is found against the primary domain zone (e.g. domain.tld) once added to your account in aws
    domain_certificate_arn = "arn:aws:acm:eu-west-2:${var.AWS_ACCOUNT_ID}:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # This is the certificate ARN which you will need to request for the domain you plan to use via aws UI first
  
    # Optional custom access policy variable
    access_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "000.000.000.000"
        }
      }
    }
  ]
}
EOF
}
```

