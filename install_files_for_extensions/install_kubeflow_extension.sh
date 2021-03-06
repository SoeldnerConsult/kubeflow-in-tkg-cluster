#!/usr/bin/env zsh

function install_kubeflow_extension(){
  pushd .
  tmpdir="/tmp/extensions"
  mkdir -p "$tmpdir"
  cd "$tmpdir"

  git clone https://github.com/SoeldnerConsult/kubeflow-extensions.git
  cd kubeflow-extensions

  kubectl apply -f resources.yaml
  chmod +x create-cert.sh
  ./create-cert.sh

  #deploy tenancy-fixer
  kubectl apply -f tenancy-fixer.yaml
  sleep 5
  mutator=$(kubectl get pods -n kubeflow-extension --selector=app=tenancy-fixer -ojsonpath='{.items[*].metadata.name}')
  kubectl -n kubeflow-extension wait --for=condition=Ready --timeout=300s pod/$mutator

  #obtain certificate from pod, which the api-server should utilize as public-key
  controller=$(kubectl -n kubeflow-extension get pods --selector=app=tenancy-fixer -o jsonpath='{.items[*].metadata.name}')
  cert=$(kubectl -n kubeflow-extension exec $controller -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 | tr -d '\n')
  sed -i.bak -E "s/caBundle:.*?/caBundle: $cert/" webhooks.yaml
  kubectl apply -f webhooks.yaml

  popd
  rm -rf "$tmpdir"
}