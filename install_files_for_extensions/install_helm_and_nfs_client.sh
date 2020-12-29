# if helm is not yet installed on your machine
function install_helm() {
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
}

# if stable charts are yet not added
function add_stable_charts_repo() {
  helm repo add stable https://charts.helm.sh/stable
}

function install_nfs_client(){
  server_ip=$1
  nfs_path=$2
  kubectl create ns nfs
  helm install nfs-provisioner -n nfs stable/nfs-client-provisioner \
    --set nfs.server="$server_ip" \
    --set nfs.path="$nfs_path" \
    --set podSecurityPolicy.enabled=true
}

