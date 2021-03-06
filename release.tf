locals {
  values_overwrite_path = "${var.helm_values_root}/values.yaml"
}

data "null_data_source" "issuers" {
  count = length(var.issuers)

  inputs = {
    resource = templatefile("${path.module}/templates/issuer.yaml", {
      private_key_secret = kubernetes_secret.ca_pk.metadata.0.name
      hosted_zone_id     = data.aws_route53_zone.zone.zone_id
      iam_role_arn       = module.iam_role.role_arn
      iam_role_name      = module.iam_role.role_id
      set_assume_config  = var.apply_assume_role_config
      name               = lookup(var.issuers[count.index], "name", "default")
      issuer_type        = lookup(var.issuers[count.index], "type", "Issuer")
      k8s_namespace      = lookup(var.issuers[count.index], "namespace", var.k8s_namespace)
      organization       = var.namespace
      email              = var.issuer_email
      aws_region         = var.aws_region
    })
  }
}

# Disable validation of CRDs from previous versions
resource "null_resource" "label_namespace" {
  count = var.disable_deprecated_crd_validation ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl label namespace ${self.triggers.k8s_namespace} certmanager.k8s.io/disable-validation=true --overwrite"
  }

  triggers = {
    k8s_namespace = var.k8s_namespace
  }
}

resource "helm_release" "cert_manager" {
  depends_on    = [null_resource.label_namespace]
  repository    = "https://charts.jetstack.io"
  name          = coalesce(var.app_name, var.name)
  namespace     = var.k8s_namespace
  chart         = "cert-manager"
  version       = var.helm_release_version
  recreate_pods = true
  wait          = true

  values = [
    file("${path.module}/defaults.yaml"),
    fileexists(local.values_overwrite_path) ? file(local.values_overwrite_path) : "",
  ]

  dynamic "set" {
    for_each = var.configure_kiam ? [1] : []

    content {
      name  = "podAnnotations.iam\\.amazonaws\\.com/role"
      value = module.iam_role.role_arn
    }
  }

  dynamic "set_sensitive" {
    for_each = var.configure_kiam && var.iam_role_with_external_id ? [1] : []

    content {
      name  = "podAnnotations.iam\\.amazonaws\\.com/external-id"
      value = module.iam_role.external_id
    }
  }
}

resource "null_resource" "apply_issuer" {
  count      = length(var.issuers)
  depends_on = [helm_release.cert_manager]

  provisioner "local-exec" {
    command = "echo \"${self.triggers.issuer}\" | kubectl apply -f -"
  }

  triggers = {
    issuer = element(data.null_data_source.issuers.*.outputs.resource, count.index)
  }
}

resource "null_resource" "destroy_issuer" {
  count = length(var.issuers)

  provisioner "local-exec" {
    when    = destroy
    command = "echo \"${self.triggers.issuer}\" | kubectl delete -f - --ignore-not-found"
  }

  triggers = {
    issuer = element(data.null_data_source.issuers.*.outputs.resource, count.index)
  }
}
