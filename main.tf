data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_subnet" "firstsub" {
  count = "${length(var.subnets_lambda) == "0" ? 0 : 1}"
  id = "${var.subnets_lambda[0]}"
}

locals {
  role_name = "${var.name}-rotation_lambda"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name}"
}

resource "aws_iam_role" "lambda_rotation" {
  name = "${local.role_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambdabasic" {
  name       = "${var.name}-lambdabasic"
  roles      = ["${aws_iam_role.lambda_rotation.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "SecretsManagerRDSPostgreSQLRotationSingleUserRolePolicy" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
    ]
    resources = [ "*",]
  }
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*",
    ]
  }
  statement {
    actions = ["secretsmanager:GetRandomPassword"]
    resources = ["*",]
  }
}

resource "aws_iam_policy" "SecretsManagerRDSPostgreSQLRotationSingleUserRolePolicy" {
  name   = "${var.name}-SecretsManagerRDSPostgreSQLRotationSingleUserRolePolicy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.SecretsManagerRDSPostgreSQLRotationSingleUserRolePolicy.json}"
}


resource "aws_iam_policy_attachment" "SecretsManagerRDSPostgreSQLRotationSingleUserRolePolicy" {
  name       = "${var.name}-SecretsManagerRDSPostgreSQLRotationSingleUserRolePolicy"
  roles      = ["${aws_iam_role.lambda_rotation.name}"]
  policy_arn = "${aws_iam_policy.SecretsManagerRDSPostgreSQLRotationSingleUserRolePolicy.arn}"
}

resource "aws_security_group" "lambda" {
    count = "${length(var.subnets_lambda) == "0" ? 0 : 1}"
    vpc_id = "${data.aws_subnet.firstsub.vpc_id}"
    name = "${var.name}-Lambda-SecretManager"
    tags = "${var.tags}"
    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
  }
}

variable "filename" { default = "rotate-code-postgres"}
resource "aws_lambda_function" "rotate-code-postgres" {
  filename           = "${path.module}/${var.filename}.zip"
  function_name      = "${var.name}-${var.filename}"
  role               = "${aws_iam_role.lambda_rotation.arn}"
  handler            = "lambda_function.lambda_handler"
  source_code_hash   = "${base64sha256(file("${path.module}/${var.filename}.zip"))}"
  runtime            = "python2.7"
  vpc_config {
    subnet_ids         = ["${var.subnets_lambda}"]
    security_group_ids = ["${local.groups}"]
  }
  timeout            = 30
  description        = "Conducts an AWS SecretsManager secret rotation for RDS PostgreSQL using single user rotation scheme"
  environment {
    variables = { #https://docs.aws.amazon.com/general/latest/gr/rande.html#asm_region
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }
}

locals {
    groups = ["${length(var.subnets_lambda) == "0" ? "" : join(",", aws_security_group.lambda.*.id)}"]
}

resource "aws_lambda_permission" "allow_secret_manager_call_Lambda" {
    function_name = "${aws_lambda_function.rotate-code-postgres.function_name}"
    statement_id = "AllowExecutionSecretManager"
    action = "lambda:InvokeFunction"
    principal = "secretsmanager.amazonaws.com"
}
/* not yet available
data "aws_iam_policy_document" "kms" {
  statement {
    sid = "Enable IAM User Permissions"
    actions = [ "*" ]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["kms:*"]
  }

  statement {
    sid = "Allow use of the key",
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type = "AWS"
      identifiers = ["${aws_iam_role.lambda_rotation.arn}"]
      #identifiers = ["${concat(list("arn:aws:iam::563249796440:role/testsecret-automatic-password-manager-rotation_lambda"),var.additional_kms_role_arn)}"]
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow attachment of persistent resources",
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    principals {
      type = "AWS"
      identifiers = ["${aws_iam_role.lambda_rotation.arn}"]
    }
    resources = ["*"]
    condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values = [ "true"]
    }
  }
}
*/

resource "aws_kms_key" "secret" {
  description         = "Key for secret ${var.name}"
  enable_key_rotation = true
  #policy              = "${data.aws_iam_policy_document.kms.json}"
  policy = <<POLICY
{
  "Id": "key-consolepolicy-3",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        ]
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${local.role_arn}"
        ]
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow attachment of persistent resources",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${local.role_arn}"
        ]
      },
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
POLICY
}



resource "aws_kms_alias" "secret" {
  name          = "alias/${var.name}"
  target_key_id = "${aws_kms_key.secret.key_id}"
}



resource "aws_secretsmanager_secret" "secret" {
  description         = "${var.secret_description}"
  kms_key_id          = "${aws_kms_key.secret.key_id}"
  name                = "${var.name}"
  rotation_lambda_arn = "${aws_lambda_function.rotate-code-postgres.arn}:$LATEST"
  rotation_rules {
    automatically_after_days = "${var.rotation_days}"
  }
  tags                = "${var.tags}"
  #policy =
}

resource "aws_secretsmanager_secret_version" "secret" {
  lifecycle {
    ignore_changes = [
      "secret_string"
    ]
  }
  secret_id     = "${aws_secretsmanager_secret.secret.id}"
  secret_string = <<EOF
{
  "username": "${var.postgres_username}",
  "engine": "postgres",
  "dbname": "${var.postgres_dbname}",
  "host": "${var.postgres_host}",
  "password": "${var.postgres_password}",
  "port": ${var.postgres_port},
  "dbInstanceIdentifier": "${var.postgres_dbInstanceIdentifier}"
}
EOF
}
