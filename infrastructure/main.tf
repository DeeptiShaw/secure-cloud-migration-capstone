terraform {
 required_providers {
  aws = { source = "hashicorp/aws", version = "~> 5.0" }
 }
}
provider "aws" { region = "ap-south-1" }
data "aws_availability_zones" "available" { state = "available" }
resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 enable_dns_support = true
 enable_dns_hostnames = true
 tags = { Name = "orders-vpc" }
}
locals {
 subnets = { for x in setproduct(["public","web","api","db"],[0,1]) : "${x[0]}-${x[1]}" => { tier=x[0], az=x[1], cidr=cidrsubnet("10.0.0.0/16",8,lookup({public=1,web=11,api=21,db=31},x[0])+x[1]) } }
}
resource "aws_subnet" "tier" {
 for_each = local.subnets
 vpc_id = aws_vpc.main.id
 cidr_block = each.value.cidr
 availability_zone = data.aws_availability_zones.available.names[each.value.az]
 map_public_ip_on_launch = false
 tags = { Name = each.key }
}
resource "aws_internet_gateway" "main" { vpc_id = aws_vpc.main.id }
resource "aws_eip" "nat" {
 count = 2
 domain = "vpc"
}
resource "aws_nat_gateway" "main" {
 count = 2
 allocation_id = aws_eip.nat[count.index].id
 subnet_id = aws_subnet.tier["public-${count.index}"].id
 depends_on = [aws_internet_gateway.main]
}
resource "aws_route_table" "tier" {
 for_each = local.subnets
 vpc_id = aws_vpc.main.id
}
resource "aws_route" "public" {
 for_each = {for k,v in local.subnets:k=>v if v.tier=="public"}
 route_table_id = aws_route_table.tier[each.key].id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.main.id
}
resource "aws_route" "private" {
 for_each = {for k,v in local.subnets:k=>v if contains(["web","api"],v.tier)}
 route_table_id = aws_route_table.tier[each.key].id
 destination_cidr_block = "0.0.0.0/0"
 nat_gateway_id = aws_nat_gateway.main[each.value.az].id
}
resource "aws_route_table_association" "tier" {
 for_each = local.subnets
 subnet_id = aws_subnet.tier[each.key].id
 route_table_id = aws_route_table.tier[each.key].id
}
resource "aws_security_group" "tier" {
 for_each = toset(["public-alb","web","internal-alb","api","db"])
 name = "orders-${each.key}"
 vpc_id = aws_vpc.main.id
}
resource "aws_vpc_security_group_ingress_rule" "public" {
 for_each = toset(["80","443"])
 security_group_id = aws_security_group.tier["public-alb"].id
 cidr_ipv4 = "0.0.0.0/0"
 ip_protocol = "tcp"
 from_port = tonumber(each.key)
 to_port = tonumber(each.key)
}
locals { links = {web={source="public-alb",port=443},internal-alb={source="web",port=443},api={source="internal-alb",port=8443},db={source="api",port=5432}} }
resource "aws_vpc_security_group_ingress_rule" "link" {
 for_each = local.links
 security_group_id = aws_security_group.tier[each.key].id
 referenced_security_group_id = aws_security_group.tier[each.value.source].id
 ip_protocol = "tcp"
 from_port = each.value.port
 to_port = each.value.port
}
resource "aws_vpc_security_group_egress_rule" "link" {
 for_each = local.links
 security_group_id = aws_security_group.tier[each.value.source].id
 referenced_security_group_id = aws_security_group.tier[each.key].id
 ip_protocol = "tcp"
 from_port = each.value.port
 to_port = each.value.port
}
resource "aws_vpc_security_group_egress_rule" "updates" {
 for_each = toset(["web","api"])
 security_group_id = aws_security_group.tier[each.key].id
 cidr_ipv4 = "0.0.0.0/0"
 ip_protocol = "tcp"
 from_port = 443
 to_port = 443
}
resource "aws_db_subnet_group" "main" {
 name = "orders-db"
 subnet_ids = [aws_subnet.tier["db-0"].id,aws_subnet.tier["db-1"].id]
}
resource "aws_db_instance" "main" {
 identifier = "orders-postgres"
 engine = "postgres"
 instance_class = var.db_instance_class
 allocated_storage = 100
 storage_type = "gp3"
 storage_encrypted = true
 multi_az = true
 publicly_accessible = false
 db_name = "orders"
 username = "dbadmin"
 manage_master_user_password = true
 db_subnet_group_name = aws_db_subnet_group.main.name
 vpc_security_group_ids = [aws_security_group.tier["db"].id]
 backup_retention_period = 7
 deletion_protection = true
 skip_final_snapshot = false
 final_snapshot_identifier = "orders-final-snapshot"
}
