#!/usr/bin/env zsh

function create_psp_yaml_file() {
  patch_path=$1
  which_namespace=$2
  echo "creating pod security policy for $which_namespace in $patch_path "

if [ "$which_namespace" = "kubeflow" ]; then
    cat << EOF >"${patch_path}/${which_namespace}-rb.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace
  labels:
    control-plane: kubeflow
    istio-injection: enabled
---
EOF
else
  cat << EOF >"${patch_path}/${which_namespace}-rb.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace
---
EOF

fi
  #create rb yaml file for each namespace
  cat << EOF >>"${patch_path}/${which_namespace}-rb.yaml"
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rb-all-sa_ns-$which_namespace
  namespace: $which_namespace
roleRef:
  kind: ClusterRole
  name: psp:vmware-system-privileged
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: Group
  apiGroup: rbac.authorization.k8s.io
  name: system:serviceaccounts:$which_namespace
EOF
  return $?
}

function update_kustomization_file() {
  kustomization_file_path=$1
  cat << EOF >> "${kustomization_file_path}"/kustomization.yaml
- ${namespace}-rb.yaml
EOF
}

function create_psp_rolebinding_patches() {
  certmanager_patch_patch="kustomize/application"
  #identified namespaces
  namespaces=(auth knative-serving istio-system kubeflow cert-manager)

  for namespace in "${namespaces[@]}"; do
    create_psp_yaml_file ${certmanager_patch_patch} "${namespace}"
    update_kustomization_file $certmanager_patch_patch
  done
}

