variable "github_repositories" {
  type    = list(string)
  default = ["test-telco-ran-5g", "test-telco-control-plane-5g", "test-telco-user-plane-5g"]  # List of repository names
}
variable "github_token" {
  description = "Github PAT"
  type = string
}
