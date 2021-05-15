terraform {
  # Terraform version at the time of writing this post
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.58.0"
    }
  }

  backend "s3" {
    bucket = "leonels3demo"
    key    = "leonels3demo.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "sa-east-1"
}