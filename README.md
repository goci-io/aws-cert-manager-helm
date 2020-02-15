# aws-cert-manager-helm

This module deploys [cert-manager](https://cert-manager.io/) using helm on AWS (Kubernetes).
A reference to another terraform module can be specified to read the issuer private key. It can also read from a file providing the private key.

In addition to the configured helm release we also deploy the `ClusterIssuer` custom resource using the details provided.
The IAM role required to change DNS records in Rotue53 is created and applied to the cluster issuer. Currently only one deployment of an Issuer is supported.

### Usage

```hcl
module "cert_manager" {
  source                = "git::https://github.com/goci-io/aws-cert-manager-helm.git?ref=tags/<latest-version>"
  namespace             = "goci"
  stage                 = "corp"
  region                = "eu1"
  name                  = "cert-manager"
  dns_zone              = "corp.eu1.goci.io"
  issuer_email          = "certs<at>@goci.io"
  ca_private_key_secret = "/etc/ssl/my-ca.pem"
}
```
