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

# seal off the default NACL
resource "aws_default_network_acl" "test_default" {
  default_network_acl_id = "${aws_vpc.test_vpc.default_network_acl_id}"

  tags {
    Name    = "Scenario2-default"
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

resource "aws_network_acl" "bastion" {
  vpc_id     = "${aws_vpc.test_vpc.id}"
  subnet_ids = ["${aws_subnet.bastion.id}"]

  tags {
    Name    = "Scenario2-bastion-nacl"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# accept SSH requets
resource "aws_network_acl_rule" "bastion_ssh_in" {
  count          = "${length(var.ssh_inbound)}"
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "${100 + count.index}"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.ssh_inbound[count.index]}"
  from_port      = 22
  to_port        = 22
}

# accept responses to YUM requets
resource "aws_network_acl_rule" "bastion_ephemeral_in" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# HTTP from protected goes via the NAT gateway
resource "aws_network_acl_rule" "bastion_http_from_protected" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = 220
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.protected_subnet_cidr}"
  from_port      = 80
  to_port        = 80
}

# allow responses to SSH requests
resource "aws_network_acl_rule" "bastion_ephemeral_out" {
  count          = "${length(var.ssh_inbound)}"
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = "${100 + count.index}"
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.ssh_inbound[count.index]}"
  from_port      = 1024
  to_port        = 65535
}

# allow YUM requests
resource "aws_network_acl_rule" "bastion_http_out" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# allow SSH to protected
resource "aws_network_acl_rule" "bastion_ssh_out" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = 220
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.protected_subnet_cidr}"
  from_port      = 22
  to_port        = 22
}

# respond to HTTP from protected
resource "aws_network_acl_rule" "bastion_ephemeral_to_protected" {
  network_acl_id = "${aws_network_acl.bastion.id}"
  rule_number    = 240
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.protected_subnet_cidr}"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl" "protected" {
  vpc_id     = "${aws_vpc.test_vpc.id}"
  subnet_ids = ["${aws_subnet.protected.id}"]

  tags {
    Name    = "Scenario2-protected-nacl"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# accept SSH requests
resource "aws_network_acl_rule" "protected_ssh_in" {
  network_acl_id = "${aws_network_acl.protected.id}"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.bastion_subnet_cidr}"
  from_port      = 22
  to_port        = 22
}

# accept responses from YUM requests
resource "aws_network_acl_rule" "protected_ephemeral_in" {
  network_acl_id = "${aws_network_acl.protected.id}"
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# allow responses to SSH requests
resource "aws_network_acl_rule" "protected_ephemeral_out" {
  network_acl_id = "${aws_network_acl.protected.id}"
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.bastion_subnet_cidr}"
  from_port      = 1024
  to_port        = 65535
}

# allow YUM requests
resource "aws_network_acl_rule" "protected_http_out" {
  network_acl_id = "${aws_network_acl.protected.id}"
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
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
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_inbound}"]
  }
}

resource "aws_security_group" "ssh_out_access" {
  name        = "Scenario2-ssh-out"
  description = "allows ssh access out"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.test_vpc_cidr}"]
  }
}

resource "aws_security_group" "http_out_access" {
  name        = "Scenario2-http-out"
  description = "allows instance to reach out on port 80"
  vpc_id      = "${aws_vpc.test_vpc.id}"

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
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
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_subnet_cidr}"]
  }
}

# --------------------------------------------------------------------------------------------------------------
# EC2 instances
# --------------------------------------------------------------------------------------------------------------
data "aws_ami" "target_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }
}

resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.target_ami.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.bastion_key}"
  subnet_id     = "${aws_subnet.bastion.id}"

  vpc_security_group_ids = [
    "${aws_security_group.bastion_ssh_access.id}",
    "${aws_security_group.http_out_access.id}",
    "${aws_security_group.ssh_out_access.id}",
  ]

  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.root_vol_size}"
  }

  tags {
    Name    = "Scenario2-bastion"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  volume_tags {
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  user_data = <<EOF
#!/bin/bash
yum update -y -q
yum erase -y -q ntp*
yum -y -q install chrony git
service chronyd start
EOF

  provisioner "file" {
    source      = "${path.root}/../data/${var.protected_key}.pem"
    destination = "/home/${var.bastion_user}/.ssh/${var.protected_key}.pem"

    connection {
      type        = "ssh"
      user        = "${var.bastion_user}"
      private_key = "${file("${path.root}/../data/${var.bastion_key}.pem")}"
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0400 /home/${var.bastion_user}/.ssh/*.pem",
    ]

    connection {
      type        = "ssh"
      user        = "${var.bastion_user}"
      private_key = "${file("${path.root}/../data/${var.bastion_key}.pem")}"
    }
  }
}

resource "aws_instance" "protected" {
  associate_public_ip_address = false
  ami                         = "${data.aws_ami.target_ami.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.protected_key}"

  vpc_security_group_ids = [
    "${aws_security_group.protected_ssh_access.id}",
    "${aws_security_group.http_out_access.id}",
  ]

  subnet_id = "${aws_subnet.protected.id}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.root_vol_size}"
  }

  tags {
    Name    = "Scenario2-protected"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  volume_tags {
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  user_data = <<EOF
#!/bin/bash
yum update -y -q
yum erase -y -q ntp*
yum -y -q install chrony git
service chronyd start
EOF
}
