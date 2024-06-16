variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "A map of tags to assign to the resource."
}
