module "cert_manager_iam_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  context    = module.label.context
  attributes = [var.region]
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"],
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.zone.id}"]
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = module.cert_manager_iam_label.id
  policy      = data.aws_iam_policy_document.cert_manager.json
  description = "Allowing Cert-Manager to change Route53 DNS records on your behalf to fulfil dns challenges"
}

data "aws_iam_policy_document" "role_trust" {
  count = var.cert_manager_trust_role == "" ? 0 : 1

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    
    principals {
      type        = "AWS"
      identifiers = [var.cert_manager_trust_role]
    }
  }
}

data "aws_iam_policy_document" "ec2_trust" {
  count = var.cert_manager_trust_role == "" ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cert_manager" {
  name               = module.cert_manager_iam_label.id
  tags               = module.cert_manager_iam_label.tags
  assume_role_policy = join("", coalescelist(data.aws_iam_policy_document.role_trust.*.json, data.aws_iam_policy_document.ec2_trust.*.json))
}
