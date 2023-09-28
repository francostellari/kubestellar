#!/usr/bin/env bash

kubectl exec -it $(kubectl get pod --selector=app=kubestellar -o jsonpath='{.items[0].metadata.name}') -c core -- bash