# Outputs for AWS EC2 instances

output "instance_ids_master" {
  description = "IDs of EC2 instances"
  value       = aws_instance.kube_server_master.id
}

output "instance_ids_workers" {
  description = "IDs of EC2 worker instances"
  value       = aws_instance.kube_server_worker[*].id
  
}

output "instance_public_ip_master" {
  description = "Public IP address of the master EC2 instance"
  value       = aws_instance.kube_server_master.public_ip
}

output "instance_public_ip_workers" {
  description = "Public IP addresses of the worker EC2 instances"
  value       = aws_instance.kube_server_worker[*].public_ip
}