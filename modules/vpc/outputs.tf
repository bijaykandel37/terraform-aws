output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "private_subnets_cidr" {
  value = aws_subnet.private.*.cidr_block
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "vpc_security_group_id" {
  value = aws_security_group.default.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "route_table_private_ids" {
  value = aws_route_table.private.*.id
}

output "nat_gw_ids" {
  value = aws_eip.gw.*.public_ip
}
