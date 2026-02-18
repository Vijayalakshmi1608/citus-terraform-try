# citus-terraform-try
This repo is for trying out citus-terraform

## Variables file usage
This project now reads required deployment inputs from `terraform.tfvars`, so you can run Terraform without passing `-var` flags.

Set these values in `terraform.tfvars` before apply:
- `existing_vpc_id`
- `existing_private_subnet_ids`
- `key_name`
- `postgresql_password`

Then run:
```bash
terraform plan
terraform apply
```
