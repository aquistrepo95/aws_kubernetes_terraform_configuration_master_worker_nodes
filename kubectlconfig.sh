#!/bin/bash

# set up kubeconfig for the regular user
echo "Setting up kubeconfig for the regular user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config