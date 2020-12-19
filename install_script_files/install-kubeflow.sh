#!/usr/bin/env zsh

function apply_kubeflow_kustomize() {
  #we exported it already, but to make sure it's working..
  export KF_DIR=${BASE_DIR}/${KF_NAME}
  #config file is from earlier..
  export CONFIG_FILE="${KF_DIR}/kfctl_istio_dex.v1.1.0.yaml"
  echo "installing kubeflow"
  kfctl apply -V -f "${CONFIG_FILE}"
}

function wait_for_kubeflowinstall() {
  counter=0
  while true; do

    num_of_pods_not_running=$(kubectl get po -A -o wide | grep -v "Running" | grep -v -c "Evicted")
    if [ "$num_of_pods_not_running" -lt 3 ]; then
      echo "everything seems to be up and running, next steps can be started! "
      break
    fi

    if [ $counter -gt 100 ]; then
      echo "we waited $((10 * 100 / 60)) minutes, still not every pod is up and running.. please have a look "
        return 1;
      break
    fi

    echo "$((num_of_pods_not_running - 2)) pods are still not ready! "
    counter=$((counter + 1))
    sleep 10
  done
}