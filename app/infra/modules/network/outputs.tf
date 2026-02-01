# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC の ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  value       = aws_vpc.main.cidr_block
}

# -----------------------------------------------------------------------------
# Subnet Outputs
# -----------------------------------------------------------------------------
output "public_subnet_id" {
  description = "Public Subnet の ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private Subnet の ID"
  value       = aws_subnet.private.id
}

output "public_subnet_cidr" {
  description = "Public Subnet の CIDR ブロック"
  value       = aws_subnet.public.cidr_block
}

output "private_subnet_cidr" {
  description = "Private Subnet の CIDR ブロック"
  value       = aws_subnet.private.cidr_block
}

# -----------------------------------------------------------------------------
# Gateway Outputs
# -----------------------------------------------------------------------------
output "internet_gateway_id" {
  description = "Internet Gateway の ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "NAT Gateway の ID"
  value       = aws_nat_gateway.main.id
}

output "nat_eip_public_ip" {
  description = "NAT Gateway の Elastic IP アドレス"
  value       = aws_eip.nat.public_ip
}

# -----------------------------------------------------------------------------
# Route Table Outputs
# -----------------------------------------------------------------------------
output "public_route_table_id" {
  description = "Public Route Table の ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private Route Table の ID"
  value       = aws_route_table.private.id
}
