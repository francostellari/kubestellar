# Deploy **KubeStellar** core in a cluster using Helm

Table of contents:

- [Deploy **KubeStellar** core in a cluster using Helm](#deploy-kubestellar-core-in-a-cluster-using-helm)
  - [Install *KubeStellar* using the Helm chart](#install-kubestellar-using-the-helm-chart)
  - [Wait for *kcp* rollout](#wait-for-kcp-rollout)
  - [Get **kubeconfig**](#get-kubeconfig)
  - [Cleanup](#cleanup)
  - [References](#references)

## Install *KubeStellar* using the Helm chart

```shell
```

## Wait for *kcp* rollout

```shell
kubectl rollout status deployment kcp --timeout=600s
```

## Get **kubeconfig**

```shell
#!/usr/bin/env bash

export EXTERNAL_HOSTNAME=kcp.apps.edgeplatform1-9ca4d14d48413d18ce61b80811ba4308-0000.us-south.containers.appdomain.cloud

echo Creating the admin.kubeconfig...
export KUBECONFIG=
kubectl get secret kcp-front-proxy-cert -o=jsonpath='{.data.tls\.crt}' | base64 -d > ca.crt
kubectl --kubeconfig=admin.kubeconfig config set-cluster base --server https://${EXTERNAL_HOSTNAME}:443 --certificate-authority=ca.crt
kubectl --kubeconfig=admin.kubeconfig config set-cluster root --server https://${EXTERNAL_HOSTNAME}:443/clusters/root --certificate-authority=ca.crt
# kubectl apply -f - <<EOF
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: cluster-admin-client-cert
#   namespace: $ns
# spec:
#   commonName: cluster-admin
#   issuerRef:
#     name: kcp-client-issuer
#   privateKey:
#     algorithm: RSA
#     size: 2048
#   secretName: cluster-admin-client-cert
#   subject:
#     organizations:
#     - system:kcp:admin
#   usages:
#   - client auth
# EOF
kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.crt}' | base64 -d > client.crt
kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.key}' | base64 -d > client.key
chmod 600 client.crt client.key
kubectl --kubeconfig=admin.kubeconfig config set-credentials kcp-admin --client-certificate=client.crt --client-key=client.key
kubectl --kubeconfig=admin.kubeconfig config set-context base --cluster=base --user=kcp-admin
kubectl --kubeconfig=admin.kubeconfig config set-context root --cluster=root --user=kcp-admin
kubectl --kubeconfig=admin.kubeconfig config use-context root



export KUBECONFIG=
kubectl get secret kcp-front-proxy-cert -o=jsonpath='{.data.tls\.crt}' | base64 -d > ca.crt
kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.crt}' | base64 -d > client.crt
kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.key}' | base64 -d > client.key
kubectl --kubeconfig=admin.kubeconfig config set-cluster base --server https://${EXTERNAL_HOSTNAME}:${EXTERNAL_PORT} --certificate-authority=$(sed -e '2,$!d' -e '$d' ca.crt | tr -d '\n')
kubectl --kubeconfig=admin.kubeconfig config set-cluster root --server https://${EXTERNAL_HOSTNAME}:${EXTERNAL_PORT}/clusters/root --certificate-authority=$(sed -e '2,$!d' -e '$d' ca.crt | tr -d '\n')
kubectl --kubeconfig=admin.kubeconfig config set-credentials kcp-admin --client-certificate=$(sed -e '2,$!d' -e '$d' client.crt | tr -d '\n') --client-key=$(sed -e '2,$!d' -e '$d' client.key | tr -d '\n')
kubectl --kubeconfig=admin.kubeconfig config set-context base --cluster=base --user=kcp-admin
kubectl --kubeconfig=admin.kubeconfig config set-context root --cluster=root --user=kcp-admin
kubectl --kubeconfig=admin.kubeconfig config use-context root
rm ca.crt client.*
export KUBECONFIG=$PWD/admin.kubeconfig



echo export KUBECONFIG=$PWD/admin.kubeconfig
```

## Cleanup

Uninstall *KubeStellar* Helm chart:

```shell
helm uninstall kubestellar
```

## References

- Paolo's Slack: https://ibm-research.slack.com/archives/C031BHTG2LB/p1695161845222849
- Paolo's Issue: https://github.com/kubestellar/kubestellar/issues/995#issuecomment-1726496678
