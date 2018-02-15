# terraform-aws-vpc
The AWS documentation on VPCs has a number of scenarios, which explore issues
around routing and privacy that are quite fundamental. One of these scenarios is
the ["VPC with public and private subnet"](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html).

This set of scripts is used to set up an example of this scenario, launching an EC2
instance in each of the subnets, and deploying SSH keys so that you can SSH to the
"public" host, and from there to the "private" host, but the private host itself does
not have a public IP. Both hosts are able to reach out to the internet for things like
patching and software installation, but are behind a NAT router. The "private" instances
send outgoing traffic through the NAT gateway.

## Usage
Using these scripts assume you have [Terraform](https://terraform.io)
installed and are familiar with it, and that you are running on some sort of Unix.
It also assumes that you have an AWS account to target the scripts against, and
a suitably empowered user set up to create VPCs, networking stuff, and EC2 instances.
