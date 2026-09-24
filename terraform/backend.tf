terraform {
  backend "s3" {
    key          = "visitor-counter/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
