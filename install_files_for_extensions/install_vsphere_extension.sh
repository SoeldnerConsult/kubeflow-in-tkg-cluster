#!/usr/bin/env zsh

function download_and_install_vsphere_extension() {
  nfs_client_sc_name=$1

  pushd .

  tmpdir="/tmp/extensions"
  mkdir -p $tmpdir
  cd $tmpdir

  git clone https://github.com/SoeldnerConsult/vSphere-extensions.git
  cd vSphere-extensions

  #setup configuration
  readWriteManyStorageClass=$nfs_client_sc_name
  resourcePath=additional/resources.yaml
  sed -i "s/nfs-client/$readWriteManyStorageClass/" $resourcePath

  #create certifcate request and sign..
  #make sure, go; cfssl cfssljson are installed
  pushd .
  cd additional
  chmod +x create-cert.sh
  ./create-cert.sh
  popd

  #create all necessary resources
  kubectl apply -f $resourcePath

  #deploy vsphere-extensions
  controller=$(kubectl -n vsphere-extensions get pods --selector=app=vsphere-extensions -ojsonpath='{.items[*].metadata.name}')
  kubectl -n vsphere-extensions wait --for=condition=Ready --timeout=300s pod/$controller

  webhookResource=additional/webhook.yaml
  cert=$(kubectl -n vsphere-extensions exec $controller -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 | tr -d '\n')
  sed -i.bak -E "s/caBundle:.*?/caBundle: $cert/" $webhookResource
  kubectl apply -f $webhookResource

  popd
  rm -rf $tmpdir
}
