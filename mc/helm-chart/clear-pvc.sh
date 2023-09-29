#!/usr/bin/env bash

set -e

oc scale deployment kcp --replicas=0
oc scale deployment kubestellar --replicas=0


oc apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: volume-debugger
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: kcp
EOF

# oc apply -f - <<EOF
# apiVersion: v1
# kind: Pod
# metadata:
#   name: test
# spec:
#   containers:
#   - name: test
#     image: redhat/ubi9
#     command: ["sleep", "3600"]
# EOF


kubectl wait --for=condition=ready pod volume-debugger --timeout=300s


oc exec -it volume-debugger -- sh -c "rm data/.admin-token-store"
oc exec -it volume-debugger -- sh -c "ls -al data/"

oc delete pod volume-debugger
oc scale deployment kcp --replicas=1
oc scale deployment kubestellar --replicas=1

oc get pods