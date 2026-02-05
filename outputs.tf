# Outputs for the VPC and EC2 instances modules

output "instance_ids_master" {
  description = "IDs of the created EC2 instances"
  value       = module.ec2_instances.instance_ids_master
}

output "instance_ids_workers" {
  description = "IDs of the created EC2 worker instances"
  value       = module.ec2_instances.instance_ids_workers

}

output "vpc_arn" {
  description = "The ARN of the created VPC"
  value       = module.vpc.vpc_arn
}

output "instance_public_ip_master" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2_instances.instance_public_ip_master
}

output "instance_public_ip_workers" {
  description = "Public IP addresses of the worker EC2 instances"
  value       = module.ec2_instances.instance_public_ip_workers
}

output "vpc_id" {
  description = "value for the VPC ID"
  value       = module.vpc.vpc_id
}