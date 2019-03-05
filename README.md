This module will create all the resources to store and rotate a PostgreSQL or Aurora password using the AWS Secrets Manager service.

# Prerequisites
* A VPC with private subnets and accessibilty to AWS Secrets Manager Endpoint, see below for more details.
* An RDS with PostgreSQL or Aurora already created and reacheable from the private subnets


# Usage Example
``` hcl
module "secret-manager-with-rotation" {
  source                        = "git::https://github.com/bbeesley/terraform-aws-secret-manager-with-rotation.git?ref=2.0.0"
  name                          = "postgres-secret-test"
  rotation_days                 = 1
  subnets_lambda                = [] # dont pass any subnets if your db is public
  postgres_username             = "postgres"
  postgres_dbname               = "test"
  postgres_host                 = "${module.rds-cluster.endpoint}"
  postgres_read_host            = "${module.rds-cluster.reader_endpoint}"
  postgres_password             = "changeme"
  postgres_dbInstanceIdentifier = "postgres-db-test"
  tags                          = "${local.tags}"
}
```


The subnets specified needs to be private and with internet access to reach the [AWS secrets manager endpoint](https://docs.aws.amazon.com/general/latest/gr/rande.html#asm_region)
You can use a NAT GW or configure your Routes with a VPC Endpoint like is described in [this guide](https://aws.amazon.com/blogs/security/how-to-connect-to-aws-secrets-manager-service-within-a-virtual-private-cloud/)

# Further details
* Interesting to [force the rotation](https://forums.aws.amazon.com/thread.jspa?threadID=280093&tstart=0)

# If you like it
Please if you like this module, thumbs up on the youtube video and leave a comment as well for any questions.
