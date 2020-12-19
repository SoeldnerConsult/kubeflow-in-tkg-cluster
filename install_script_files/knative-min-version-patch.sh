#!/usr/bin/env zsh

#KUBERNETES_MIN_VERSION
#is based on the utilized virtualmachineimage we've declared earlier for the tkg cluster
#but it differs significantly from the provided string, obtain
#the necessary version value via kubectl get nodes -o wide
#in the corresponding tkg cluster

function create_knative_patch_file() {
  kub_version=$(kubectl get nodes | awk '{print $5}' | tail -n 1)
  echo 'creating patchfile'
  cat << EOF > kustomize/knative/knative-deploy-patch.yaml
- op: add
  path: /spec/template/spec/containers/0/env/-
  value:
    name: KUBERNETES_MIN_VERSION
    value: $kub_version
EOF
  return $?
}

function add_patch_segment() {
  echo "adding $comp patch"
  comp=$1
  cat << EOF >>kustomize/knative/kustomization.yaml
- path: knative-deploy-patch.yaml
  target:
    group: apps
    version: v1
    kind: Deployment
    name: $comp
    namespace: knative-serving
EOF
  return $?
}

function patch_knative_deployment_errors() {
  if create_knative_patch_file ; then
    echo "created knative patch file "
  else
    echo "could not create knative patch file "
    return 1
  fi

  echo "creating patch header "
  cat << EOF >>kustomize/knative/kustomization.yaml
patchesJson6902:
EOF

  # shellcheck disable=SC2181
  if [ $? -eq 0 ] ; then

    echo "creating kustomize file with patches "
    #kubeflow has 6 components, which we need to patch
    list=(activator autoscaler autoscaler-hpa controller networking-istio webhook)
    for comp in "${list[@]}"; do
      if ! add_patch_segment "$comp"; then
        echo "Could not create patch component for $comp "
        return 1
      fi
    done
  else
    echo "Could not write to file kustomize/knative/kustomization.yaml should clean up created knative-patch-file "
    return 1
  fi
  return 0
}