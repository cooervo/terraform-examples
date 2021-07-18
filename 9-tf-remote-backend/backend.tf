terraform {
  backend "s3" {
    // Creates a tfstate.tfstate file inside the S3
    // bucket defined below
    bucket = "s3-terraform-state-bucket-example"

    // We don't need to put it inside a folder
    // but in case we want to manage multiple in same
    // S3 bucket we can put it in subdir to differentiate
    // from others
    key = "my-app-dir/tfstate.tfstate"
    region = "us-east-1"

  }
}
