#!/usr/bin/env bash

###
# lines divided by more than 2 empty lines must be executed independently
###
allset=0

function check_for_set_var() {
  if [[ ! -n $1 ]]; then
    echo "1"
  else
    echo "0"
  fi
}

val=$(check_for_set_var $storageclass)
allset=$((allset + val))
val=$(check_for_set_var $namespace)
allset=$((allset + val))
val=$(check_for_set_var $clustername)
allset=$((allset + val))
val=$(check_for_set_var $supervisor_ip)
allset=$((allset + val))
val=$(check_for_set_var $username_and_domain)
allset=$((allset + val))

if [[ $allset -ne 0 ]]; then
  echo "you need to set and export the following variables:"
  echo "export storageclass=??"
  echo "export namespace=??"
  echo "export clustername=??"
  echo "export supervisor_ip=??"
  echo "export username_and_domain=??"
  echo ""
  echo "we exit the program now"
  return 1
fi

#obtain storage class via "kubectl get sc" ;;example storage class
#storageclass=gold-tanzu-kubernetes-storage-policy
#obtain virtualmachineclass via "kubectl get virtualmachineclasses"
vmclass_cp=guaranteed-medium
vmclass_worker=guaranteed-xlarge
#obtain virtualmachineimage via "kubectl get virtualmachineimages"
vm_image=v1.17.8+vmware.1-tkg.1.5417466
#your namespace
##namespace=kubeflow-ns #example namespace
#your cluster name
#clustername=kubeflow-tkg #example clustername
#ip of workload management cluster ip
#supervisor_ip=10.4.10.1 #example supervisor ip
#utilized username for logging into the cluster
#username_and_domain=administrator@vsphere.local #example username and domain
#1 or 3
control_machine_count=1
#at least 7
#   three are enough, if you increase harddrive storage of each worker to 64GB manually
#   via ESXi Clients on each respective ESXi Server
worker_machine_count=7

#where are we?, find the current dir.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
subdir="install_script_files"
source "${DIR}/${subdir}/create-tkg-cluster.sh"
source "${DIR}/${subdir}/patching-tkg-api-server.sh"
source "${DIR}/${subdir}/prepare-kubeflow.sh"
source "${DIR}/${subdir}/PSP-rolebinding-patch.sh"
source "${DIR}/${subdir}/knative-min-version-patch.sh"
source "${DIR}/${subdir}/install-kubeflow.sh"
source "${DIR}/${subdir}/post-patch-argo.sh"
source "${DIR}/${subdir}/open-up-services.sh"
source "${DIR}/${subdir}/post-patch-argo.sh"
source "${DIR}/${subdir}/ldap_connector_configuration_script.sh"

function install() {
  #prepare some environment variables and login
  prepare_tkg_cluster_creation $storageclass $vmclass_cp $vmclass_worker \
  $vm_image $namespace $clustername $supervisor_ip $username_and_domain

  #if succesfully logged in, proceed with cluster creation
  create_cluster $supervisor_ip $clustername $namespace $vm_image \
  $control_machine_count $worker_machine_count

  #if cluster was successfully installed, patch the api server
  append_api_server_flags $supervisor_ip $namespace $clustername $username_and_domain

  #download kubeflow files
  download_and_unpack_kubeflow
  create_local_kubeflow_kustomize_build

  #when api server patch is finished, proceed with kubeflow preinstall patching
  create_psp_rolebinding_patches
  patch_knative_deployment_errors

  #install kubeflow and wait for it to be ready
  apply_kubeflow_kustomize
  wait_for_kubeflowinstall

  #well, patch argo in kubernetes
  post_patch_argo_from_docker_to_pns

  #allow access to kubeflow
  make_kubeflow_accessible_via_https_from_outside

  #BEFORE you proceed with this step I !!!highly!!! recommend
  #Reading this blogpost:
  #https://cloudadvisors.net/2020/09/23/ldap-active-directory-with-kubeflow-within-tkg/
  #for getting a clue, what we're trying to do..
  #we do NOT want to follow the whole script and import the
  #whole LDAP / AD Directory, but at least you'll understand, which
  #information are necessary in the following variables!

  #if you missconfigure this step, you need to fix it
  #manually in the corresponding yaml file with
  #kubectl edit configmap dex
  host="DC1.vdi.sclabs.net"
  bindDN="cn=kates,ou=UEMUsers,dc=vdi,dc=sclabs,dc=net"
  #caution with the password, as for example an exclamation mark (!) may cause trouble
  #if this is the case, it may be better to put in a dummy
  #password and after that, to edit the configmap manually
  #  with insertion of the correct password in your favorite editor i.e. vim
  bindPW="<pwOfKatesUser>"
  username_prompt="vdi user + domain, e.g. kevin@vdi.sclabs.net"
  baseDN="ou=UEMUsers,dc=vdi,dc=sclabs,dc=net"
  username_attribute="userPrincipalName"
  id_attribute="sAMAccountName"
  email_attribute="userPrincipalName"
  name_attribute="displayName"

  configure_dex_ldap_connector $host $bindDN $bindPW "$username_prompt" \
  $baseDN $username_attribute $id_attribute $email_attribute $name_attribute

  #if you need to change pw:
  kubectl edit -n auth cm dex
  kubectl rollout restart deployment dex -n auth
}
