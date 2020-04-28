# aws-cert-manager-helm

**Maintained by [@goci-io/prp-terraform](https://github.com/orgs/goci-io/teams/prp-terraform)**

![Terraform Validate](https://github.com/goci-io/aws-cert-manager-helm/workflows/Terraform%20Validate/badge.svg?branch=master&event=push)

This module deploys [cert-manager](https://cert-manager.io/) using helm on AWS (Kubernetes).
A reference to another terraform module state can be specified to read the issuer private key. Another option is to reference a file providing the private key in pem format. The IAM role required to change DNS records in Rotue53 is created and applied to the cluster issuer. Currently only one deployment of an Issuer is supported.

The default version of the helm chart is currently an alpha version to support automatically creating CustomResourceDefinition's with correct configuration and namespace. The version used for now is `v0.15.0-alpha.2`. If you dont need automated installation of CRDs you can change the version for example to `v0.14.2` (current stable at the moment of writing).

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

#### Use a module for the private key ref

1. Create a LetsEncrypt Account [using this module](https://github.com/goci-io/letsencrypt-account)  
2. Expose an output called `account_key_pem` containing the private key in pem format (makred as `sensitive`)  
3. Store state of the letsencrypt module for example on S3 under `/letsencrypt/terraform.tfstate` 
4. Configure this module to use the remote state of the existing module:

```hcl
module "cert_manager" {
  ...
  ca_module_state = "letsencrypt/terraform.tfstate"
  tf_bucket       = "my-terraform-state-bucket"
}
```

#### Creating Issuer

You can either let this module create a `ClusterIssuer` or `Issuer` (default). An issue is bound to the namespace cert-manager will be deployed into.
Specify `issuer_type` to set your desired issuer type.
