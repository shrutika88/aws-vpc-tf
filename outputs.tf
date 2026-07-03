output "my_vpc_id" {
  value = module.network.vpc_id
}

output "my_public_subnet_id" {
  value = module.public_subnet_1.subnet_id
}

output "my_private_subnet_id" {
  value = module.private_subnet_1.subnet_id
}

output "my_igw_id" {
  value = module.my_igw.igw_id
}

output "public_route_table_id" {
  value = module.my_rt.route_table_id
}

output "route_table_association_id" {
  value = module.my_rt_association.rt_association_id
}

output "security_group_id" {
  value = module.ec2_sg.my_sg_id
}

output "my_ec2_instance_id" {
  value = module.my_wed_ec2.my_ec2_id
}

output "my_ec2_instance_pulic_ip" {
  value = module.my_wed_ec2.public_ip
}

output "my_elastic_ip" {
  value = module.nat_eip.public_ip
}

output "my_elastic_id" {
  value = module.nat_eip.allocation_id
}

output "my_nat_gw_id" {
  value = module.my_nat_gateway.my_nat_gw_id
}

output "dns_name" {
  value = module.my_alb.alb_dns_name
}
