data "aws_iam_policy_document" "cert_manager" {
  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.zone.id}"]
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
  }

  dynamic "statement" {
    for_each = var.iam_role_zone_grants

    content {
      effect    = "Allow"
      resources = ["arn:aws:route53:::hostedzone/${statement.value}"]
      actions = [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets",
      ]
    }
  }
}

module "iam_role" {
  source             = "git::https://github.com/goci-io/aws-iam-assumable-role.git?ref=tags/0.3.0"
  namespace          = var.namespace
  stage              = var.stage
  attributes         = var.attributes
  name               = var.name
  with_external_id   = var.iam_role_with_external_id
  role_name_override = var.iam_role_name_override
  trusted_iam_arns   = [var.cert_manager_trust_role]
  trusted_services   = var.iam_role_trusted_services
  policy_json        = data.aws_iam_policy_document.cert_manager.json
}
