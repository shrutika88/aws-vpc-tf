provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "./modules/network"

  cidr_block = "10.0.0.0/16"
  name       = "ShrutikaVPC"
}

module "public_subnet_1" {
  source = "./modules/subnet"

  vpc_id            = module.network.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  name              = "ShrutikaPublicSN1"
}

module "public_subnet_2" {
  source = "./modules/subnet"

  vpc_id            = module.network.vpc_id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  name              = "ShrutikaPublicSN2"
}

module "private_subnet_1" {
  source = "./modules/subnet"

  vpc_id            = module.network.vpc_id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"
  name              = "ShrutikaPrivateSN1"
}

module "private_subnet_2" {
  source = "./modules/subnet"

  vpc_id            = module.network.vpc_id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"
  name              = "ShrutikaPrivateSN2"
}

module "my_igw" {
  source = "./modules/internet_gateway"

  vpc_id = module.network.vpc_id
  name   = "ShrutikaIGW"
}

module "my_rt" {
  source = "./modules/route_table"

  vpc_id     = module.network.vpc_id
  gateway_id = module.my_igw.igw_id
  name       = "ShrutikaPublicRT"
}

module "my_rt_association" {
  source = "./modules/route_table_association"

  subnet_id      = module.public_subnet_1.subnet_id
  route_table_id = module.my_rt.route_table_id
}

module "my_rt_association_2" {
  source = "./modules/route_table_association"

  subnet_id      = module.public_subnet_2.subnet_id
  route_table_id = module.my_rt.route_table_id
}

module "ec2_sg" {
  source = "./modules/security_group"

  name   = "my_security_group"
  vpc_id = module.network.vpc_id

  ingress_rules = [
    {
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  security_groups = [module.bastion_sg.my_sg_id]
    },
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.alb_sg.my_sg_id]
    }
  ]
}

module "nat_eip" {
  source = "./modules/elastic_ip"
}

module "my_nat_gateway" {
  source = "./modules/nat_gateway"

  allocation_id = module.nat_eip.allocation_id
  name          = "my_nat_gateway"
  subnet_id     = module.public_subnet_1.subnet_id
}

module "my_nat_rt" {
  source = "./modules/route_table"

  vpc_id         = module.network.vpc_id
  nat_gateway_id = module.my_nat_gateway.my_nat_gw_id
  name           = "ShrutikaPrivateRT"
}

module "my_private_rt_association" {
  source = "./modules/route_table_association"

  subnet_id      = module.private_subnet_1.subnet_id
  route_table_id = module.my_nat_rt.route_table_id
}

module "my_private_rt_association_2" {
  source = "./modules/route_table_association"

  subnet_id      = module.private_subnet_2.subnet_id
  route_table_id = module.my_nat_rt.route_table_id
}

module "my_private_ec2" {
  source = "./modules/compute"

  ami                 = "ami-06067086cf86c58e6"
  subnet_id           = module.private_subnet_1.subnet_id
  instance_type       = "t3.micro"
  security_group_id   = module.ec2_sg.my_sg_id
  name                = "my_private_ec2"
  key_name            = "tf-3-tier-demo"
  associate_public_ip = false
}

module "alb_sg" {
  source = "./modules/security_group"

  name   = "alb-security-group"
  vpc_id = module.network.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "my_alb" {
  source = "./modules/alb"

  name = "my-alb"

  security_group_id = module.alb_sg.my_sg_id

  subnet_ids = [
    module.public_subnet_1.subnet_id,
    module.public_subnet_2.subnet_id
  ]
}

module "my_target_group" {
  source = "./modules/target_group"

  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"

  vpc_id = module.network.vpc_id
}

module "my_listener" {
  source = "./modules/listener"

  load_balancer_arn = module.my_alb.alb_arn
  target_group_arn  = module.my_target_group.target_group_arn
}


module "launch_template" {
  source = "./modules/launch_template"

  name              = "tier-3-EC2_launch_template"
  ami               = "ami-06067086cf86c58e6"
  instance_type     = "t3.micro"
  key_name          = "tf-3-tier-demo"
  security_group_id = module.ec2_sg.my_sg_id
  # user_data         = file("${path.module}/scripts/user_data.sh")
  user_data = templatefile(
  "${path.module}/scripts/user_data.sh.tpl",
  {
    db_endpoint = module.my_rds.address
    db_name     = "appdb"
    db_user     = "admin"
    db_password = "YOUR_PASSWORD"
  }
)
}

module "my_asg" {
  source = "./modules/auto_scaling_group"

  name = "web-asg"

  launch_template_id = module.launch_template.launch_template_id

  subnet_ids = [
    module.private_subnet_1.subnet_id,
    module.private_subnet_2.subnet_id
  ]

  target_group_arns = [
    module.my_target_group.target_group_arn
  ]

  desired_capacity = 2
  min_size         = 2
  max_size         = 4
}

module "db_subnet_group" {
  source = "./modules/db_subnet_group"

  subnet_ids = [module.private_subnet_1.subnet_id,
  module.private_subnet_2.subnet_id]
  name = "my_db_subnet_group"
}

module "db_sg" {
  source = "./modules/security_group"

  name   = "db-security-group"
  vpc_id = module.network.vpc_id

  ingress_rules = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      security_groups = [module.ec2_sg.my_sg_id]
    }
  ]
}

module "my_rds" {
  source = "./modules/rds"

  identifier          = "mydb"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20

  db_name             = "appdb"
  username            = var.db_username
  password            = var.db_password

  db_subnet_group_name = module.db_subnet_group.db_subnet_group_name
  security_group_id    = module.db_sg.my_sg_id
}


module "bastion_sg" {
  source = "./modules/security_group"

  name   = "bastion-security-group"
  vpc_id = module.network.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # We'll tighten this later.
    }
  ]
}

module "bastion" {
  source = "./modules/compute"

  ami                 = "ami-06067086cf86c58e6"
  instance_type       = "t3.micro"

  subnet_id           = module.public_subnet_1.subnet_id

  security_group_id   = module.bastion_sg.my_sg_id

  key_name            = "tf-3-tier-demo"

  associate_public_ip = true

  name = "bastion-host"
}
