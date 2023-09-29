#!/usr/bin/env bash

echo Uninstalling KubeStellar Helm chart from the current namespace...
helm uninstall kubestellar

oc delete secret kubestellar
