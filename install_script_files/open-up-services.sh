#!/usr/bin/env zsh

function patch_http_redirect_and_enable_https(){
  cat << EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kubeflow-gateway
  namespace: kubeflow
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - '*'
    port:
      name: http
      number: 80
      protocol: HTTP
    # Upgrade HTTP to HTTPS
    tls:
      httpsRedirect: true
  - hosts:
    - '*'
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: SIMPLE
      privateKey: /etc/istio/ingressgateway-certs/tls.key
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
EOF
  return $?
}

function expose_with_loadbalancer() {
  kubectl patch service -n istio-system istio-ingressgateway -p '{"spec": {"type": "LoadBalancer"}}'
}

function obtain_kubeflow_lb_ip() {
  kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

function create_kubeflow_certificates() {
  if [ $# -ne 1 ]; then
    echo "ip should be provided.. canceling creating of certificate"
    return 1
  fi

  kubeflowIp=$1
  cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: istio-ingressgateway-certs
  namespace: istio-system
spec:
  commonName: istio-ingressgateway.istio-system.svc
  ipAddresses:
  - $kubeflowIp
  isCA: true
  issuerRef:
    kind: ClusterIssuer
    name: kubeflow-self-signing-issuer
  secretName: istio-ingressgateway-certs
EOF

  return 0
}

function wait_for_kubeflow_to_be_ready() {
  lb_ip=$1
  for i in $(seq 50); do
    if curl -k "https://${lb_ip}/" -v; then
      echo "service is up and running "
      return 0
    else
      echo "service not yet ready waiting some seconds. "
      echo "This was try: $i of 50"
      sleep 10
    fi
  done
  echo "kubeflow is not yet ready.. please retry"
  return 1
}

function wait_for_kubeflow_lb_ip() {
  maxTries=50
  for i in $(seq $maxTries); do
    echo "waiting for ip of loadbalancer; try #${i} from $maxTries "
    ipOfKubeflowService=$(obtain_kubeflow_lb_ip)
    if echo "$ipOfKubeflowService" | grep '^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$'; then
      echo "found ip of loadbalancer! "
      echo "using $ipOfKubeflowService "
      break
    else
      if [ "$i" -ge $maxTries ]; then
        echo "Max tries exceeded.. Cancelling operation, check whether or not the IP is given to the service"
        return 1
      fi

      echo "no ip adress yet.. retrying in some seconds "
      sleep 5
    fi
  done
}

function make_kubeflow_accessible_via_https_from_outside() {
  patch_http_redirect_and_enable_https
  expose_with_loadbalancer
  if wait_for_kubeflow_lb_ip; then
    ipOfKubeflowService=$(obtain_kubeflow_lb_ip)
    create_kubeflow_certificates "$ipOfKubeflowService"
    wait_for_kubeflow_to_be_ready "$ipOfKubeflowService"
  fi
}

