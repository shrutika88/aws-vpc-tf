resource "aws_route_table" "my_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = var.gateway_id
    nat_gateway_id = var.nat_gateway_id
  }
  tags = {
    Name = var.name
  }
}
