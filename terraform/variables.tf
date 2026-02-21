variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "jenkins-flask-cicd"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your public IP /32 for SSH"
  type        = string
}

variable "allowed_jenkins_cidr" {
  description = "Your public IP /32 for Jenkins UI (8080)"
  type        = string
}
