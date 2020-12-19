#!/usr/bin/env bash

#now we're going to install some additional
#applications into our kubernetes cluster
#extending the functionality of kubeflow

#make sure you've installed an NFS client before..
#i.e. via HELM

#installing the vSphere extension:
#https://github.com/SoeldnerConsult/vSphere-extensions

#installing the kubeflow extension:
#https://github.com/SoeldnerConsult/kubeflow-extensions

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
subdir="install_files_for_extensions"

source "${DIR}/${subdir}/install_vsphere_extension.sh"
source "${DIR}/${subdir}/install_kubeflow_extension.sh"


#before executing this, make sure you have
#git, go, cfssl and cfssljson installed
nfs_client_sc_name="nfs-client"
download_and_install_vsphere_extension "$nfs_client_sc_name"

#before executing this, make sure you have
#git, go, cfssl and cfssljson installed
install_kubeflow_extension
