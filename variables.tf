
variable "namespace" {
  type        = string
  description = "Organization or company namespace prefix"
}

variable "stage" {
  default     = ""
  description = "The stage the deployment covers"
}

variable "environment" {
  default     = ""
  description = "The environment the deployment covers"
}

variable "region" {
  type        = string
  description = "Custom region name the deployment is for"
}

variable "attributes" {
  type        = list
  default     = []
  description = "Additional attributes (e.g. `eu1`)"
}

variable "tags" {
  type        = map
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name` and `attributes`"
}

variable "dns_zone" {
  type        = string
  description = "Name of the dns zone to create validation records in"
}

variable "private_zone" {
  type        = bool
  default     = false
}

variable "ca_module_state" {
  type        = string
  default     = ""
  description = "S3 Bucket key referencing a file with terraform state information. Must expose an attribute called account_key_pem containing the private key for the ca issuer. Requires tf_bucket to be set to the S3 Bucket"
}

variable "tf_bucket" {
  type        = string
  default     = ""
  description = "S3 Bucket name containing state information for the ca module"
}

variable "ca_private_key_secret" {
  type        = string
  default     = ""
  description = "Either path to a file containing the private key or the plain private key. Can be used if ca_module_state is not set"
}

variable "cert_manager_trust_role" {
  type        = string
  default     = ""
  description = "Role ARN allowed to assume the role created for the cert manager. If not set the trust relationship will allow EC2 to assume the role"
}