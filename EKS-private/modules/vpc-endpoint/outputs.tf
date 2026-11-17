output "interface_endpoint_ids" {
  value = {
    for service, endpoint in aws_vpc_endpoint.interface :
    service => endpoint.id
  }
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}
