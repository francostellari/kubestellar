#!/usr/bin/env bash

echo Uninstalling KubeStellar Helm chart from the current namespace...
helm uninstall kubestellar

echo Deleting the cluster-admin-client-cert certificate...
oc delete certificate cluster-admin-client-cert
