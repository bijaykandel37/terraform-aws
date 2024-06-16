locals {
  tags = {
    Environment = local.stage
    Creator     = "DevOps"
    Project     = "apply"
    Deletable   = "false"
  }
  stage = "dev"
}