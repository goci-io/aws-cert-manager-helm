terraform {
  required_version = ">= 0.12.1"

  required_providers {
    null       = "~> 2.1"
    helm       = "~> 1.0"
    kubernetes = "~> 1.11"
  }
}

provider "aws" {
  version = "~> 2.45"

  assume_role {
    role_arn = var.aws_assume_role_arn
  }
}

module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace   = var.namespace
  stage       = var.stage
  environment = var.environment
  attributes  = var.attributes
  delimiter   = var.delimiter
  tags        = var.tags
  name        = var.name
}

data "aws_route53_zone" "zone" {
  name         = format("%s.", var.dns_zone)
  private_zone = var.private_zone
}
