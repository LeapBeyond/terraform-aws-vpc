provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# --------------------------------------------------------------------------------------------------------------
# define the test VPC
# --------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "test_vpc" {
  cidr_block           = "${var.test_vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name    = "Scenario2-vpc"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# seal off the default security group
resource "aws_default_security_group" "test_default" {
  vpc_id = "${aws_vpc.test_vpc.id}"

  tags {
    Name    = "Scenario2-default"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_internet_gateway" "testgateway" {
  vpc_id = "${aws_vpc.test_vpc.id}"

  tags {
    Name    = "Scenario2-gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define the two subnets
# --------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "bastion" {
  vpc_id                  = "${aws_vpc.test_vpc.id}"
  cidr_block              = "${var.bastion_subnet_cidr}"
  map_public_ip_on_launch = true

  tags {
    Name    = "Scenario2-bastion-subnet"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_subnet" "protected" {
  vpc_id                  = "${aws_vpc.test_vpc.id}"
  cidr_block              = "${var.protected_subnet_cidr}"
  map_public_ip_on_launch = false

  tags {
    Name    = "Scenario2-protected-subnet"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define the nat gateway in the bastion subnet
# --------------------------------------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  vpc                       = true
  associate_with_private_ip = "${var.eip_nat_ip}"

  tags {
    Name    = "Scenario2-eip"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.bastion.id}"

  tags {
    Name    = "Scenario2-nat-gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define routing tables for the two subnets
# --------------------------------------------------------------------------------------------------------------
resource "aws_route_table" "bastion" {
  vpc_id = "${aws_vpc.test_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.testgateway.id}"
  }

  tags {
    Name    = "bastion-rt"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_route_table_association" "bastion" {
  subnet_id      = "${aws_subnet.bastion.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

resource "aws_route_table" "protected" {
  vpc_id = "${aws_vpc.test_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags {
    Name    = "protected-rt"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_route_table_association" "protected" {
  subnet_id      = "${aws_subnet.protected.id}"
  route_table_id = "${aws_route_table.protected.id}"
}

# --------------------------------------------------------------------------------------------------------------
# security groups
# --------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "bastion_ssh_access" {
  name        = "Scenario2-bastion-ssh"
  description = "allows ssh access to the bastion host"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_inbound}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "protected_ssh_access" {
  name        = "Scenario2-protected-ssh"
  description = "allows ssh access to protected host from bastion subnet"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_subnet_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
