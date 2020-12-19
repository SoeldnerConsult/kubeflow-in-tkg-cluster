#!/usr/bin/env zsh

function configure_dex_ldap_connector(){
host=$1
bindDN=$2
bindPW=$3
username_prompt=$4
baseDN=$5
username_attribute=$6
id_attribute=$7
email_attribute=$8
name_attribute=$9

#1. obtain actual auth config
kubectl get configmap dex -n auth -o jsonpath='{.data.config\.yaml}' > dex-config.yaml

#2. create new auth
cat << EOF >> dex-config.yaml
connectors:
- type: ldap
  id: ldap
  name: LDAP
  config:
    host: "$host"
        #This is the user which has read access to AD
    bindDN: "$bindDN"
        #This is the password for the above account
    bindPW: "$bindPW"
        #What the user is going to see in Kubeflow
    insecureSkipVerify: true
    usernamePrompt: "$username_prompt"
    userSearch:
          #Which AD/LDAP users may access Kubeflow
      baseDN: "$baseDN"
          #This is the mapping I've talked about and I'll explain again
      username: "$username_attribute"
      idAttr: "$id_attribute"
      emailAttr: "$email_attribute"
      nameAttr: "$name_attribute"
EOF
#3 & 4 create dummy configmap and merge with actual
kubectl create configmap dex \
--from-file=config.yaml=dex-config.yaml \
-n auth --dry-run -oyaml | kubectl apply -f -

#5 reapply auth
kubectl rollout restart deployment dex -n auth
}