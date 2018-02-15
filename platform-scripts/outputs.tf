output "nat_ip" {
  value = "${aws_eip.nat.public_ip}"
}
