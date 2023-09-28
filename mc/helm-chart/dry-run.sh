#!/usr/bin/env bash

 helm install kubestellar . \
    --set kcp.externalHostname=kcp.apps.edgeplatform1-9ca4d14d48413d18ce61b80811ba4308-0000.us-south.containers.appdomain.cloud \
    --set kcp.kcp.volumeClassName=ibmc-block-gold \
   --dry-run --debug  > /vagrant/kubestellar.yaml