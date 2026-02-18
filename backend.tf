terraform {
  backend "s3" {
    bucket         = "smac-terraform-state"
    key            = "trail/terraform.tfstate"
    region         = "ap-south-1"
    # dynamodb_table = "smac-terraform-locks"
    encrypt        = true
    profile        = "smac-staging" 
  }
}