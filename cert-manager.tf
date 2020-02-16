
locals {
  issuer_resource = templatefile("${path.module}/templates/issuer.yaml", {
    name               = format("%s-%s", var.namespace, var.name)
    private_key_secret = kubernetes_secret.ca_pk.metadata.0.name
    dns_zones          = [var.dns_zone, "*.${var.dns_zone}"]
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

resource "helm_release" "cert_manager" {
  name          = coalesce(var.app_name, var.name)
  repository    = data.helm_repository.jetstack.metadata.0.name
  chart         = "stable/cert-manager"
  namespace     = "kube-system"
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
