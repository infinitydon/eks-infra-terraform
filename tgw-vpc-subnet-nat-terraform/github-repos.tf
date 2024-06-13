resource "tls_private_key" "github_ssh_key" {
  for_each    = toset(var.github_repositories)
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "aws_secretsmanager_secret" "github_credentials" {
  for_each    = toset(var.github_repositories)
  name_prefix = "${each.key}-git-credentials"
}

resource "aws_secretsmanager_secret_version" "github_credentials_version" {
  for_each      = toset(var.github_repositories)
  secret_id     = aws_secretsmanager_secret.github_credentials[each.key].id
  secret_string = jsonencode({
    private_key = tls_private_key.github_ssh_key[each.key].private_key_pem,
    public_key  = tls_private_key.github_ssh_key[each.key].public_key_openssh
  })
}

resource "github_repository" "gitops" {
  for_each   = toset(var.github_repositories)
  name       = each.key
  description = each.key
  visibility = "public"
  auto_init  = true
}

resource "github_repository_deploy_key" "gitops" {
  for_each  = toset(var.github_repositories)
  title     = "Flux"
  repository = github_repository.gitops[each.key].name
  key       = tls_private_key.github_ssh_key[each.key].public_key_openssh
  read_only = false
}