variable "name" {
  description = "This name will be used as prefix for all the created resources"
}

variable "secret_description" {
  description = "This field is the description for the secret manager object"
  default     = "secret manager for postgres/aurora"
}

variable "rotation_days" {
  default     = 30
  description = "How often in days the secret will be rotated"
}

variable "subnets_lambda" {
  type        = "list"
  description = "The subnets where the Lambda Function will be run"
}

variable "postgres_username" {
  description = "The PostgreSQL/Aurora username you chose during RDS creation or another one that you want to rotate"
}

variable "postgres_dbname" {
  description = "The Database name inside your RDS"
}

variable "postgres_host" {
  description = "The RDS endpoint to connect to your database"
}

variable "postgres_read_host" {
  description = "The RDS read only endpoint to connect to your database"
  default     = ""
}

variable "postgres_password" {
  description = "The password that you want to rotate, this will be changed after the creation"
}

variable "postgres_port" {
  default     = 5432
  description = "In case you don't have your PostgreSQL on default port and you need to change it"
}

variable "postgres_dbInstanceIdentifier" {
  description = "The RDS Identifier in the webconsole"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Info tags to be applied to infrastructure we create"
}

/* Not yet available 
variable "additional_kms_role_arn" {
  type = "list"
  default = [""]
  description = "If you want add another role of another resource to access to the kms key used to encrypt the secret"
}
*/

