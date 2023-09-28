#!/usr/bin/env bash

export externalHostname=kcp.apps.edgeplatform1-9ca4d14d48413d18ce61b80811ba4308-0000.us-south.containers.appdomain.cloud
export ns=fs

echo Creating the admin.kubeconfig...

kubectl get secret kcp-front-proxy-cert -n $ns -o=jsonpath='{.data.tls\.crt}' | base64 -d > ca.crt
kubectl --kubeconfig=admin.kubeconfig config set-cluster base --server https://${externalHostname}:443 --certificate-authority=ca.crt
kubectl --kubeconfig=admin.kubeconfig config set-cluster root --server https://${externalHostname}:443/clusters/root --certificate-authority=ca.crt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cluster-admin-client-cert
  namespace: $ns
spec:
  commonName: cluster-admin
  issuerRef:
    name: kcp-client-issuer
  privateKey:
    algorithm: RSA
    size: 2048
  secretName: cluster-admin-client-cert
  subject:
    organizations:
    - system:kcp:admin
  usages:
  - client auth
EOF
kubectl get secret cluster-admin-client-cert -n $ns -o=jsonpath='{.data.tls\.crt}' | base64 -d > client.crt
kubectl get secret cluster-admin-client-cert -n $ns -o=jsonpath='{.data.tls\.key}' | base64 -d > client.key
chmod 600 client.crt client.key
kubectl --kubeconfig=admin.kubeconfig config set-credentials kcp-admin --client-certificate=client.crt --client-key=client.key
kubectl --kubeconfig=admin.kubeconfig config set-context base --cluster=base --user=kcp-admin
kubectl --kubeconfig=admin.kubeconfig config set-context root --cluster=root --user=kcp-admin
kubectl --kubeconfig=admin.kubeconfig config use-context root


echo export KUBECONFIG=$PWD/admin.kubeconfig
