# citus-terraform-try
This repo is for trying out citus-terraform

## Variables file usage
This project reads required deployment inputs from `terraform.tfvars` (ignored by git), so you can run Terraform without passing `-var` flags.

Start by copying the template and then set values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

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
