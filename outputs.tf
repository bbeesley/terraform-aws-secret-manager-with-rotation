output "secret_arn" {
  value = "${aws_secretsmanager_secret.secret.arn}"
  description = "The arn for the secrets-manager secret"
}

output "secret_id" {
  value = "${aws_secretsmanager_secret.secret.id}"
  description = "The id for the secrets-manager secret"
}
