output "vpc_id" {
  value = aws_vpc.test_vpc
}

output  "subnet_id" {
  value = aws_subnet.test_subnet
}

output "route_table_id" {
  value = aws_route_table.test_route_table  
}

