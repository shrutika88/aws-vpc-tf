resource "aws_launch_template" "web" {
  name_prefix   = var.name
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name

  update_default_version = true

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.name
    }
  }
}
