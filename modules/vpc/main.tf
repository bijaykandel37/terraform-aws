# Fetch AZ in current Region
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    {
      Name = "${var.stage}-${var.namespace}-vpc"
    },
    var.tags
  )
}

# Create a Private Subnet
resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.tags,
    {
      Name = join(var.delimiter, [var.stage, var.namespace, "private", count.index]),
      Type = "private"
    }
  )
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags,
    {
      Name = join(var.delimiter, [var.stage, var.namespace, "public", count.index]),
      Type = "public"
    }
  )
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags,
    {
      Name = join(var.delimiter, [var.stage, var.namespace, "igw"])
    }
  )
}

# Route the Public Subnet through IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Create a NAT gateway with an EIP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
  count  = var.az_count
  domain = "vpc"
  tags = merge(
    {
      Name = join(var.delimiter, [var.stage, var.namespace, "eip", count.index])
    }, var.tags
  )
  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_nat_gateway" "gw" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)
  tags = merge(
    {
      Name = join(var.delimiter, [var.stage, var.namespace, "nat", count.index])
    }, var.tags
  )
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }
  tags = merge(
    {
      Name = join(var.delimiter, [var.stage, var.namespace, "route-table", count.index]),
      Type = "private"
    }, var.tags
  )
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_security_group" "default" {
  name        = join("-", [var.stage, var.namespace, "vpc", "security-group"])
  description = "${var.stage} ${var.namespace} security group"
  vpc_id      = aws_vpc.main.id
  tags = merge(
    {
      Name = join("-", [var.stage, var.namespace, "vpc", "security-group"]),
      Type = "default"
    }, var.tags
  )
}

resource "aws_vpc_security_group_egress_rule" "default" {
  security_group_id = aws_security_group.default.id
  description       = "${var.stage} ${var.namespace} egress rule"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "default" {
  security_group_id = aws_security_group.default.id
  description       = "${var.stage} ${var.namespace} Allow all traffic within VPC"
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}

