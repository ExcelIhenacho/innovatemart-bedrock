terraform {
  backend "s3" {
    bucket       = "innovatemart-tfstate-excel"
    key          = "envs/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
