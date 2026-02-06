# Terraform configuration to create nodes for Kubernetes deployment on AWS.

## Functional Terraform infrastructure project to run a single control plane node and two worker nodes(the configuration could be modified to run as many nodes as needed).

## This project showcases the following concepts in Terraform:
* Deploying AWS infrastructure using Terraform to provision components like: VPC, EC2, security groups, etc.
* Deploying Kubernetes control plane and worker components to run on AWS infrastructure.

## Built with:
* Terraform
* AWS CLI
* Docker: Docker engine, Docker CRI(Container Runtime Interface).
* Kubernetes: Kubeadm, Kubectl, Kubelet.
* BASH: script to provide Kubernetes, control-plane, and worker components.

## This section will describe: how to deploy the infrastructure on AWS.
* Prequisite: Terraform is installed, and AWS CLI is installed and configured with keys.
* Generate private and public keys and copy them to ssh_keys and ssh_keys.pub.
  ```
  $ ssh-keygen -C "your_email@example.com" -f ssh_keys
  ```
* Run Terraform commands to deploy the infrastructure to AWS.
  ```
  $ terraform fmt
  $ terraform init
  $ terrafrom validate
  $ terraform apply
  ```
  NB: This may take a few minutes to complete.

## Verification
* To verify if the nodes are up and running, follow the steps below:
* ssh to the master/control plane node
  ```
  $ ssh ubuntu@$(terraform output -raw instance_public_ip_master) -i ssh_keys -v
  ```
  NB: You can ssh to any worker node using the instance_public_ip_worker[*] - where [*] is the worker count.
* You should now be connected to the master node.
* run the following commands to ensure all nodes in the cluster are available, and all essential Kubernetes control plane components have been created:
  ```
  ubuntu@master-node:~$ kubectl get nodes
  NAME            STATUS   ROLES           AGE   VERSION
  master-node     Ready    control-plane   20m   v1.35.0
  worker-node-1   Ready    <none>          19m   v1.35.0
  worker-node-2   Ready    <none>          18m   v1.35.0
  
  ubuntu@master-node:~$ kubectl get pods -A
  NAMESPACE     NAME                                  READY   STATUS    RESTARTS      AGE
  kube-system   coredns-7d764666f9-5khcn              1/1     Running   0             21m
  kube-system   coredns-7d764666f9-c8jnb              1/1     Running   0             21m
  kube-system   etcd-master-node                      1/1     Running   0             21m
  kube-system   kube-apiserver-master-node            1/1     Running   0             21m
  kube-system   kube-controller-manager-master-node   1/1     Running   0             21m
  kube-system   kube-proxy-4skfs                      1/1     Running   0             19m
  kube-system   kube-proxy-5s7kn                      1/1     Running   0             21m
  kube-system   kube-proxy-9qzp6                      1/1     Running   0             19m
  kube-system   kube-scheduler-master-node            1/1     Running   0             21m
  kube-system   weave-net-2fn5k                       2/2     Running   1 (19m ago)   19m
  kube-system   weave-net-4gp7q                       2/2     Running   1 (21m ago)   21m
  kube-system   weave-net-nm8lr                       2/2     Running   1 (19m ago)   19m

  ```
* The master/control plane node and the worker nodes are ready. 
