#!/usr/bin/env zsh

function post_patch_argo_from_docker_to_pns() {
  #patch argo to use pns
  kubectl get -n kubeflow configmaps workflow-controller-configmap -o yaml | sed "s/containerRuntimeExecutor: docker/containerRuntimeExecutor: pns/" | kubectl apply -f -

  #and restart the deployment
  kubectl rollout restart deployment/ml-pipeline -n kubeflow
}
