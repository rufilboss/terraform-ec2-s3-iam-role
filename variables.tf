variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "tf-ec2-s3-demo"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name in this region"
  type        = string
}

variable "ssh_cidr" {
  description = "Your public IP in CIDR format for SSH access (example: 203.0.113.10/32)"
  type        = string
}
