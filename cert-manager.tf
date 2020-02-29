
locals {
  issuer_resource = templatefile("${path.module}/templates/issuer.yaml", {
    name               = format("%s-%s", var.namespace, var.name)
    private_key_secret = kubernetes_secret.ca_pk.metadata.0.name
    common_name        = data.aws_route53_zone.zone.name
    hosted_zone_id     = data.aws_route53_zone.zone.zone_id
    iam_role_arn       = aws_iam_role.cert_manager.arn
    email              = var.issuer_email
    aws_region         = var.aws_region
  })
}

data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

# Disable validation of CRDs from previous versions
resource "null_resource" "label_namespace" {
  count = var.disable_deprecated_crd_validation ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl label namespace ${var.k8s_namespace} certmanager.k8s.io/disable-validation=true --overwrite"
  }
}

resource "helm_release" "cert_manager" {
  depends_on    = [null_resource.apply_crds, null_resource.label_namespace]
  repository    = data.helm_repository.jetstack.metadata.0.name
  name          = coalesce(var.app_name, var.name)
  namespace     = var.k8s_namespace
  chart         = "jetstack/cert-manager"
  version       = "v0.13.0"
  recreate_pods = true
  wait          = true

  values = [
    file("${path.module}/defaults.yaml"),
    file("${var.helm_values_root}/values.yaml"),
  ]
}

resource "null_resource" "apply_issuer" {
  depends_on = [helm_release.cert_manager]

  provisioner "local-exec" {
    command = "echo \"${local.issuer_resource}\" | kubectl apply -f -"
  }
}

resource "null_resource" "destroy_issuer" {
  depends_on = [null_resource.apply_issuer]

  provisioner "local-exec" {
    when    = destroy
    command = "echo \"${local.issuer_resource}\" | kubectl delete -f - --ignore-not-found"
  }
}
