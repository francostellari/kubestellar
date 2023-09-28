#!/usr/bin/env bash

export externalHostname=kcp.apps.edgeplatform1-9ca4d14d48413d18ce61b80811ba4308-0000.us-south.containers.appdomain.cloud
export ns=fs

# helm install kubestellar . \
#     --namespace $ns \
#     --set kcp.externalHostname=$externalHostname \
#     --set EXTERNAL_HOSTNAME=$externalHostname \
#     --set clusterType=OpenShift \
#     --set kcp.kcpFrontProxy.openshiftRoute.enabled=true \
#     --set kcp.volumeClassName=ibmc-block-gold  \
#     --dry-run --debug > /vagrant/kubestellar.yaml


# oc create ns $ns
# helm install kubestellar . \
#     --namespace $ns \
#     --set kcp.externalHostname=$externalHostname \
#     --set EXTERNAL_HOSTNAME=$externalHostname \
#     --set clusterType=OpenShift \
#     --set kcp.kcpFrontProxy.openshiftRoute.enabled=true \
#     --set kcp.volumeClassName=ibmc-block-gold

# helm install kubestellar . \
#     --set kcp.externalHostname=$externalHostname \
#     --set EXTERNAL_HOSTNAME=$externalHostname \
#     --set clusterType=OpenShift \
#     --set kcp.kcpFrontProxy.openshiftRoute.enabled=true \
#     --set kcp.volumeClassName=ibmc-block-gold

# helm uninstall kubestellar
# oc delete certificate cluster-admin-client-cert -n $ns


 helm install kubestellar . \
    --set kcp.externalHostname=kcp.apps.edgeplatform1-9ca4d14d48413d18ce61b80811ba4308-0000.us-south.containers.appdomain.cloud \
    --set kcp.kcp.volumeClassName=ibmc-block-gold

    #  \
    # --dry-run --debug  > /vagrant/kubestellar.yaml