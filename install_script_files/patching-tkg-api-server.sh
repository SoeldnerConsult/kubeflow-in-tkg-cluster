#!/usr/bin/env zsh

function append_api_server_flags(){
supervisor_ip=$1
namespace=$2
clustername=$3
username_and_domain=$4

#log into tkg-cluster
kubectl-vsphere login \
--vsphere-username="$username_and_domain"  \
--server="$supervisor_ip" \
--tanzu-kubernetes-cluster-namespace="$namespace" \
--tanzu-kubernetes-cluster-name="$clustername"

#step 1 obtain pw of node on supervisor cluster
kubectl config use-context "$supervisor_ip"
pw=$(kubectl get secret "${clustername}"-ssh-password -o jsonpath='{.data.ssh-passwordkey}' -n "$namespace"| base64 -d)

#step 2 obtain ips from control plane nodes within the private kubernetes network
kubectl config use-context "$clustername"
node_ips=$(kubectl get nodes -o jsonpath=\
"{range .items[*]}{.metadata.name}{'\t'}{.metadata.annotations.projectcalico\.org/IPv4IPIPTunnelAddr}{'\n'}" \
| grep control-plane | awk '{print $2}')

#step 4 create POD with ubuntu container in TKG Cluster
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu
spec:
  containers:
  - name: ubuntu
    image: ubuntu:focal
    command:
    -  sh
    -  '-c'
    -  "while true; do echo working; sleep 100; done;"
EOF
kubectl wait --for=condition=Ready --timeout=300s pod/ubuntu

#this last step is rather ugly. because we ssh multiple levels and use
#variable substitution in different hosts, so we sometimes break up double quotes and use single quotes.
kubectl exec ubuntu -- bash -c "\
{
#install necessary tools
apt update
apt upgrade -y
apt install -y sshpass openssh-client
pw=$pw

for node in ${node_ips[@]}; do
  "'#use inner variable substitution
    sshpass -p $pw  ssh -o "StrictHostKeyChecking=no" vmware-system-user@$node \
    '\''apiServerFile=/etc/kubernetes/manifests/kube-apiserver.yaml; \
    sudo sed -i "s,- --tls-private-key-file=/etc/kubernetes/pki/apiserver.key,- --tls-private-key-file=/etc/kubernetes/pki/apiserver.key\n\    - --service-account-issuer=kubernetes.default.svc\n\    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key," $apiServerFile '\''
  '"
done;
}"
kubectl delete po ubuntu

}