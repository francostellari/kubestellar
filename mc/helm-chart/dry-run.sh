#!/usr/bin/env bash

helm install kubestellar . \
   --set global.EXTERNAL_HOSTNAME=kcp.apps.edgeplatform1-9ca4d14d48413d18ce61b80811ba4308-0000.us-south.containers.appdomain.cloud  \
   --dry-run --debug  > /vagrant/kubestellar.yaml