terraform {
  backend "s3" {
    bucket         = "test-tf-201923-state-bucket"
    key            = "5g-ran-cluster/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "test-tf-201923-state-lock"
    encrypt        = true
  }  
}