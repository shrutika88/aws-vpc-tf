variable "name" {
  type = string
}

variable "launch_template_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "target_group_arns" {
  type = list(string)
}

variable "desired_capacity" {
  type = number
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}
