module "vpc" {
  source = "./modules/vpc"
  stage  = local.stage
  tags   = local.tags
}

module "nacl" {
  source = "./modules/nacl"
  vpc_id = module.vpc.vpc_id
}
