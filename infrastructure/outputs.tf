output "vpc_id" { value = aws_vpc.main.id }
output "subnets" { value = {for k,v in aws_subnet.tier:k=>v.id} }
output "security_groups" { value = {for k,v in aws_security_group.tier:k=>v.id} }
output "database_endpoint" { value = aws_db_instance.main.address }
