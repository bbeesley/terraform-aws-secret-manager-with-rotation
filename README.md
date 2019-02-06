This module will create all the resources to store and rotate a PostgreSQL or Aurora password using the AWS Secrets Manager service.

# Prerequisites
* A VPC with private subnets and accessibilty to AWS Secrets Manager Endpoint, see below for more details.
* An RDS with PostgreSQL or Aurora already created and reacheable from the private subnets


# Usage Example
``` hcl
module "secret-manager-with-rotation" {
  source                     = "giuseppeborgese/secret-manager-with-rotation/aws"
  version                    = "<always choose the latest version displayed in the upper right corner of this page>"
  name                       = "PassRotation"
  rotation_days              = 10
  subnets_lambda             = ["subnet-xxxxxx", "subnet-xxxxxx"] # or [] for no vpc
  postgres_username             = "giuseppe"
  postgres_dbname               = "my_db_name"
  postgres_host                 =  "postgresEndpointurl.xxxxxx.us-east-1.rds.amazonaws.com"
  postgres_password             = "dummy_password_will_we_rotated"
  postgres_dbInstanceIdentifier = "my_rds_db_identifier"
}
```


The subnets specified needs to be private and with internet access to reach the [AWS secrets manager endpoint](https://docs.aws.amazon.com/general/latest/gr/rande.html#asm_region)
You can use a NAT GW or configure your Routes with a VPC Endpoint like is described in [this guide](https://aws.amazon.com/blogs/security/how-to-connect-to-aws-secrets-manager-service-within-a-virtual-private-cloud/)

# Further details
* Interesting to [force the rotation](https://forums.aws.amazon.com/thread.jspa?threadID=280093&tstart=0)

# If you like it
Please if you like this module, thumbs up on the youtube video and leave a comment as well for any questions.
