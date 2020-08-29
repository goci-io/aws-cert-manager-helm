terraform {
  required_version = ">= 0.12.1"

  required_providers {
    null       = "~> 2.1"
    helm       = "~> 1.0"
    kubernetes = "~> 1.11"
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

module "iam_role" {
  source             = "git::https://github.com/goci-io/aws-iam-assumable-role.git?ref=master"
  namespace          = var.namespace
  stage              = var.stage
  attributes         = var.attributes
  name               = var.name
  role_name_override = var.iam_role_name_override
  trusted_iam_arns   = [var.cert_manager_trust_role]
  trusted_services   = var.iam_role_trusted_services
  policy_json        = data.aws_iam_policy_document.cert_manager.json
}

data "aws_route53_zone" "zone" {
  name         = format("%s.", var.dns_zone)
  private_zone = var.private_zone
}
