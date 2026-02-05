# AWS Compute resources for Kubernetes Cluster: Master and Worker Nodes

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


################################################################# master instance ###########################################################

resource "aws_instance" "kube_server_master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type.master
  subnet_id                   = var.instance_subnet_id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.public_ssh_key.key_name
  vpc_security_group_ids      = [ aws_security_group.k8s-master-sg.id ]

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("ssh_keys")
    host = self.public_ip
  }

  provisioner "file" {
    source      = "./master.sh"
    destination = "/home/ubuntu/master.sh"
  }

  provisioner "file" {
    source = "./kubectlconfig.sh"
    destination = "/home/ubuntu/kubectlconfig.sh"
  }

  provisioner "remote-exec" {
    inline = [
        "chmod a+x /home/ubuntu/master.sh",
        "sudo sh /home/ubuntu/master.sh master-node",
        "chmod a+x /home/ubuntu/kubectlconfig.sh",
        "sh /home/ubuntu/kubectlconfig.sh"
    ]  
  }

  provisioner "local-exec" {
    command = <<EOF
      ssh ubuntu@${self.public_ip} -o StrictHostKeyChecking=no -i ssh_keys "kubeadm token create --print-join-command" >> ./join_command.sh
      sed -i '' 's/$/ \\/' join_command.sh
      echo "--cri-socket unix:///var/run/cri-dockerd.sock" >> join_command.sh
    EOF
  }

  tags = merge(
    var.instance_tags,
    {
      Name = "Kube-Server_master"
    }
  ) 
}

################################################################ master security group #############################################################

resource "aws_security_group" "k8s-master-sg" {
  name        = "allow_traffic_master"
  description = "Allow inbound  and outbound traffic to k8s master node"
  vpc_id      = var.vpc_id_instance

  tags = {
    Name = "allow_master_traffic_sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "k8s-master-sg-egress" {
  security_group_id = aws_security_group.k8s-master-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4_master" {
  description       = "SSH from anywhere"  
  security_group_id = aws_security_group.k8s-master-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_k8s_api_server_ipv4" {
  description       = "Allow K8s API Server for control plane"  
  security_group_id = aws_security_group.k8s-master-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "etcd_server_ipv4" {
  description       = "Allow etcd server communication for control plane"
  security_group_id = aws_security_group.k8s-master-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 2379
  ip_protocol       = "tcp"
  to_port           = 2380
}

resource "aws_vpc_security_group_ingress_rule" "kublet_ipv4" {
  description       = "Allow kubelet communication for control plane"  
  security_group_id = aws_security_group.k8s-master-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10250
  ip_protocol       = "tcp"
  to_port           = 10250
}

resource "aws_vpc_security_group_ingress_rule" "kube-scheduler_ipv4" {
  description       = "Allow kube-scheduler communication for control plane"  
  security_group_id = aws_security_group.k8s-master-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10259
  ip_protocol       = "tcp"
  to_port           = 10259
}

resource "aws_vpc_security_group_ingress_rule" "kube-controller-manager_ipv4" {
  description       = "Allow kube-controller-manager communication for control plane"  
  security_group_id = aws_security_group.k8s-master-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10257
  ip_protocol       = "tcp"
  to_port           = 10257
}



################################################################# worker instances ###########################################################

resource "aws_instance" "kube_server_worker" {
  count                       = var.worker_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type.worker
  subnet_id                   = var.instance_subnet_id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.public_ssh_key.key_name
  vpc_security_group_ids      = [ aws_security_group.k8s-worker-sg.id ]
  depends_on                  = [ aws_instance.kube_server_master ]

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("ssh_keys")
    host = self.public_ip
  }

  provisioner "file" {
    source      = "./worker.sh"
    destination = "/home/ubuntu/worker.sh"
  }
   
  provisioner "file" {
    source      = "./join_command.sh"
    destination = "/home/ubuntu/join_command.sh"
  } 
  
  provisioner "remote-exec" {
    inline = [
        "chmod a+x /home/ubuntu/worker.sh",
        "sudo sh /home/ubuntu/worker.sh worker-node-${count.index + 1}",
        "chmod a+x /home/ubuntu/join_command.sh",
        "sudo sh /home/ubuntu/join_command.sh" 
    ]  
  }

  tags = merge(
    var.instance_tags,
    {
      Name = "Kube-Worker-${count.index + 1}"
    }
  ) 
}

################################################################# worker security group ###########################################################

resource "aws_security_group" "k8s-worker-sg" {
  name        = "allow_traffic_worker"
  description = "Allow inbound  and outbound traffic to k8s worker nodes"
  vpc_id      = var.vpc_id_instance

  tags = {
    Name = "allow_worker_traffic_sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "k8s-worker-sg-egress" {
  security_group_id = aws_security_group.k8s-worker-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4_worker" {
  description       = "SSH from anywhere"  
  security_group_id = aws_security_group.k8s-worker-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "kublet_ipv4_worker" {
  description       = "Allow kubelet communication for worker nodes"  
  security_group_id = aws_security_group.k8s-worker-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10250
  ip_protocol       = "tcp"
  to_port           = 10250
}

resource "aws_vpc_security_group_ingress_rule" "kube-proxy_ipv4" {
  description       = "Allow kube-proxy communication for worker nodes"  
  security_group_id = aws_security_group.k8s-worker-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10256
  ip_protocol       = "tcp"
  to_port           = 10256
}

resource "aws_vpc_security_group_ingress_rule" "node-port_ipv4_tcp" {
  description       = "Allow NodePort services communication for worker nodes(TCP)"  
  security_group_id = aws_security_group.k8s-worker-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 30000
  ip_protocol       = "tcp"
  to_port           = 32767
}

resource "aws_vpc_security_group_ingress_rule" "node-port_ipv4_udp" {
  description       = "Allow NodePort services communication for worker nodes(UDP)"  
  security_group_id = aws_security_group.k8s-worker-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 30000
  ip_protocol       = "udp"
  to_port           = 32767
}


################################################################ SSH Key Pair ###############################################################
resource "aws_key_pair" "public_ssh_key" {
  key_name = "ssh_keys"
  public_key = file("ssh_keys.pub")
}
