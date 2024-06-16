variable "az_count" {
  type    = string
  default = "2"
}

variable "cidr_block" {
  type    = string
  default = "172.13.0.0/16"
}

variable "namespace" {
  description = "Namespace (e.g. `fhf`)"
  type        = string
  default     = "test"
}

variable "stage" {
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
  type        = string
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name` and `attributes`"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}
