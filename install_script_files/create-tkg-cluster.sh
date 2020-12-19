#!/usr/bin/env zsh

#CAUTION
#PROCEEDING WITH THIS SCRIPT YOUR
#CURRENT TKG CONFIGURATION WILL BE DELETED;

function prepare_tkg_cluster_creation() {
  #obtain storage class via "kubectl get sc"
  storageclass=$1
  #obtain virtualmachineclass via "kubectl get virtualmachineclasses"
  vmclass_cp=$2
  vmclass_worker=$3
  #obtain virtualmachineimage via "kubectl get virtualmachineimages"
  vm_image=$4
  #your namespace
  namespace=$5
  #your cluster name
  clustername=$6
  #ip of workload management cluster ip
  supervisor_ip=$7
  #utilized username for logging into the cluster
  username_and_domain=$8

  #export some tkg relevant variables
  export CONTROL_PLANE_STORAGE_CLASS=$storageclass
  export WORKER_STORAGE_CLASS=$storageclass
  export DEFAULT_STORAGE_CLASS=$storageclass
  export STORAGE_CLASSES=
  export SERVICE_DOMAIN=cluster.local #this is necessary, do not change!
  export CONTROL_PLANE_VM_CLASS=$vmclass_cp
  export WORKER_VM_CLASS=$vmclass_worker
  export SERVICE_CIDR=100.64.0.0/13 #use whatever you want to
  export CLUSTER_CIDR=100.96.0.0/11 #use whatever you want to

  #clean up old tkg settings
  mv ~/.tkg/config.yaml ~/.tkg/config.yaml.bak
  rm -f ~/.tkg/config.yaml

  #setup tkg again (done in earlier posts)
  kubectl vsphere login --server="$supervisor_ip" \
  --vsphere-username "$username_and_domain"
}

function create_cluster(){
  #proceed, when logged in
  supervisor_ip=$1
  clustername=$2
  namespace=$3
  vm_image=$4
  control_machine_count=$5
  worker_machine_count=$6

  kubectl config use-context "$supervisor_ip"
  tkg add mc "$supervisor_ip"
  tkg set mc "$supervisor_ip"

  #create TKG Cluster
  tkg create cluster "$clustername" --plan=dev --namespace="$namespace" \
  --kubernetes-version="$vm_image" --controlplane-machine-count="$control_machine_count" \
  --worker-machine-count="$worker_machine_count"

  rm -f ~/.tkg/config.yaml
  mv ~/.tkg/config.yaml.bak ~/.tkg/config.yaml
}
