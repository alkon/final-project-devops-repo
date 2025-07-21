terraform {
  backend "s3" {
    bucket         = "alkon-terraform-state-dev"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}