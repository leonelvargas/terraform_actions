terraform {
  # Terraform version at the time of writing this post
  required_version = ">= 0.14.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.21"
    }
  }

  backend "s3" {
    bucket = "leonels3demo"
    key    = "leonels3demo.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  profile = "terraform"
  region  = "sa-east-1"
}