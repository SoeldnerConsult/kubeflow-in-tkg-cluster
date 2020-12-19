#!/usr/bin/env zsh

function download_and_unpack_kubeflow() {
  echo "downloading kfctl and exporting path"
  # Add kfctl to PATH, to make the kfctl binary easier to use.
  # Use only alphanumeric characters or - in the directory name.
  rm -rf /tmp/kube/kfctl_tmp
  rm -rf /tmp/kubeflowtmp/
  mkdir -p /tmp/kube/kfctl_tmp
  cd /tmp/kube/kfctl_tmp
  wget https://github.com/kubeflow/kfctl/releases/download/v1.1.0/kfctl_v1.1.0-0-g9a3621e_linux.tar.gz
  tar -xvf kfctl_*.tar.gz
  rm kfctl_v1.1.0-0-g9a3621e_linux.tar.gz
  export PATH=$PATH:"/tmp/kube/kfctl_tmp"
}

function create_local_kubeflow_kustomize_build() {
  echo "creating initial install suite for kubeflow"
  # Set the following kfctl configuration file:
  export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.1-branch/kfdef/kfctl_istio_dex.v1.1.0.yaml"
  # Set KF_NAME to the name of your Kubeflow deployment. You also use this
  # value as directory name when creating your configuration directory.
  # For example, your deployment name can be 'my-kubeflow' or 'kf-test'.
  export KF_NAME=kf-devenv

  # Set the path to the base directory where you want to store one or more
  # Kubeflow deployments. For example, /opt.
  # Then set the Kubeflow application directory for this deployment.
  export BASE_DIR="/tmp/kubeflowtmp"
  export KF_DIR=${BASE_DIR}/${KF_NAME}

  mkdir -p ${KF_DIR}
  cd ${KF_DIR}

  # Download the config file and change default settings.
  kfctl build -V -f ${CONFIG_URI}
  export CONFIG_FILE="${KF_DIR}/kfctl_istio_dex.v1.1.0.yaml"
}

download_and_unpack_kubeflow
create_local_kubeflow_kustomize_build

