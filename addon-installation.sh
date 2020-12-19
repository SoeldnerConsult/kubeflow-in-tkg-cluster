#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
subdir="install_files_for_extensions"

source "${DIR}/${subdir}/install_vsphere_extension.sh"
source "${DIR}/${subdir}/install_kubeflow_extension.sh"
source "${DIR}/${subdir}/install_helm_and_nfs_client.sh"

#if you have not installed helm yet
install_helm
#if you have not yet added the stable charts repo
add_stable_charts_repo
#install nfs client, but you need to provide your nfs server values:
#these are sample values, based on my environment
#the ip is from an nfs server you have access to, from WITHIN the kubernetes Cluster
#the path is a configured path on the nfs server, which we want to mount
#it's absolutely necessary, that you have configured.
# 1. NON root mount possibility within the NFS server
# 2. sub dir mount possibility within the NFS server
server_ip="10.0.21.100"
nfs_path="/mnt/Pool1"
install_nfs_client $server_ip $nfs_path

#now we're going to install some additional
#applications into our kubernetes cluster
#extending the functionality of kubeflow

#make sure you've installed an NFS client before..
#i.e. via HELM

#installing the vSphere extension:
#https://github.com/SoeldnerConsult/vSphere-extensions

#installing the kubeflow extension:
#https://github.com/SoeldnerConsult/kubeflow-extensions




#before executing this, make sure you have
#git, go, cfssl and cfssljson installed
nfs_client_sc_name="nfs-client" #if you did not manually change the nfs client install function, then this is correct
download_and_install_vsphere_extension "$nfs_client_sc_name"

#before executing this, make sure you have
#git, go, cfssl and cfssljson installed
install_kubeflow_extension
