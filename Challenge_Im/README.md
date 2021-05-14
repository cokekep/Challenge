# Prerequisites (Relevant for Task 1 and 2)
* Terraform should be installed. See [Terraform Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* An AWS IAM User with access to the required aws resources. The access key ID and secret access key.
* Have a key pair. Add this key pair name (as is relevant for yout environmrnt) as default in the variables.tf file

# Task 1
This Terraform project creates resources on AWS as outlined in the Task 1.

It runs a dockerized nginx server on an EC2 instance, and serves traffic from an Application Load balancer on port 80.

To run this part of the task, get the ALB endpoint URL from the AWS Console after Terraform is done creating resources.

# To deploy this code, use:
* terraform init
* terraform apply

# To destroy resources, use: 
* terraform destroy


# Notes to Task 1
* I have included a block for ALB HTTPS listener  to redirect http-to-https. This code block is, however, commented out due to AWS free tier constraints. It is of note that serving the traffic on the load balancer via HTTPS  port that requires a R53 domain name which might incur additional charges. 

# Task 2
All the points on this task is addressed in the solution. The terraform code creates an ASG with Capacities for Desired, Min and Max Values set to 3, 2, 5 respectively.
A seperate instance called Cron-runner is created to run script.py, and it has all necessary IAM privileges to make changes to ASG definitions.

The script.py runs in the Cron runner instance to update the ASG as needed, and it run in two different possible scenarios:
1. If user initiates the script manaully, then values for the requested changes are required at the terminal.
2. If run by cron, then the script default to DEFAULT values for MIN, MAX and DESIRED capacities.

**To run code**, simply do: python3 script.py




