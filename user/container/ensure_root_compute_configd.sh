#!/usr/bin/env bash

# Copyright 2023 The KubeStellar Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

function create_or_replace() { # usage: filename
    filename="$1"
    kind=$(grep kind: "$filename" | head -1 | awk '{ print $2 }')
    name=$(grep name: "$filename" | head -1 | awk '{ print $2 }')
    if kubectl get "$kind" "$name" &> /dev/null ; then
        kubectl replace -f "$filename"
    else
        kubectl create -f "$filename"
    fi
}

echo "Ensuring configd for root:compute..."

if ! kubectl ws root:compute &> /dev/null ; then
    echo "$0: Something is very wrong, unable to set current kcp workspace to root:compute" >&2
    exit 1
fi

( cd /home/kubestellar/config/kube/exports/namespaced
    # Some are too big to `kubectl apply`
    for rsfn in apiresourceschema-*.yaml; do
        create_or_replace $rsfn
    done
    for refn in apiexport-*.yaml; do
        kubectl apply -f "$refn"
    done
)

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: compute:apiexport:kubernetes-extended:bind
rules:
- apiGroups:
  - apis.kcp.io
  resourceNames:
  - apps
  - autoscaling
  - batch
  - core.k8s.io
  - discovery.k8s.io
  - networking.k8s.io
  - policy
  - storage.k8s.io
  resources:
  - apiexports
  verbs:
  - bind
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: compute:apiexport:kubernetes:maximal-permission-policy-extended
rules:
- apiGroups:
  - ""
  - apps
  - networking.k8s.io

  - autoscaling
  - batch
  - discovery.k8s.io
  - policy
  - storage.k8s.io
  resources:
  - services
  - pods
  - ingresses
  - deployments

  - cronjobs
  - csistoragecapacities
  - daemonsets
  - endpoints
  - endpointslices
  - horizontalpodautoscalers
  - jobs
  - networkpolicies
  - persistentvolumeclaims
  - poddisruptionbudgets
  - podtemplates
  - replicasets
  - replicationcontrollers
  - statefulsets
  verbs:
  - "*"
- apiGroups:
  - ""
  - apps
  - networking.k8s.io

  - autoscaling
  - batch
  - discovery.k8s.io
  - policy
  - storage.k8s.io
  resources:
  - services/status
  - pods/status
  - ingresses/status
  - deployments/status
  - deployments/scale

  - cronjobs/status
  - csistoragecapacities/status
  - daemonsets/status
  - endpoints/status
  - endpointslices/status
  - horizontalpodautoscalers/status
  - jobs/status
  - networkpolicies/status
  - persistentvolumeclaims/status
  - poddisruptionbudgets/status
  - podtemplates/status
  - replicasets/scale
  - replicasets/status
  - replicationcontrollers/scale
  - replicationcontrollers/status
  - statefulsets/scale
  - statefulsets/status
  verbs:
  - get
  - list
  - watch
  - update
  - patch
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: compute:apiexport:kubernetes-extended:bind
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: compute:apiexport:kubernetes-extended:bind
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: apis.kcp.io:binding:system:authenticated
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: compute:authenticated:apiexport:kubernetes:maximal-permission-policy-extended
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: compute:apiexport:kubernetes:maximal-permission-policy-extended
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: apis.kcp.io:binding:system:authenticated
EOF

echo "Finished augmenting root:compute for KubeStellar"