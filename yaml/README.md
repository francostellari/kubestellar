# Deploy **KubeStellar** service in a Kind cluster

Table of contests:
- [Deploy **KubeStellar** service in a Kind cluster](#deploy-kubestellar-service-in-a-kind-cluster)
  - [Deploy **KubeStellar** in a Kind cluster](#deploy-kubestellar-in-a-kind-cluster)
  - [Access **KubeStellar** service directly from the host without KUBECONFIG or executables](#access-kubestellar-service-directly-from-the-host-without-kubeconfig-or-executables)
  - [Access **KubeStellar** service from the host](#access-kubestellar-service-from-the-host)
  - [Access **KubeStellar** service from another pod in the same `kubestellar` namespace](#access-kubestellar-service-from-another-pod-in-the-same-kubestellar-namespace)

## Deploy **KubeStellar** in a Kind cluster

Start a **Kind** cluster:

```shell
$ kind create cluster
```

Deploy **KubeStellar** `stable` in `kubestellar` namespace

```shell
$ kubectl apply -f kubestellar-server.yaml
namespace/kubestellar created
persistentvolumeclaim/kubestellar-pvc created
deployment.apps/kubestellar-server created
```

Wait for **KubeStellar** to be ready:

```shell
$ kubectl logs -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name})

< Starting Kubestellar container >-------------------------
< Starting kcp >-------------------------------------------
Running kcp... pid= logfile=/kubestellar-logs/kcp.log
Waiting for kcp to be ready... it may take a while
kcp version: v0.11.0
Current workspace is "root".
< Starting KubeStellar >-----------------------------------
Finished augmenting root:compute for KubeStellar
Workspace "espw" (type root:organization) created. Waiting for it to be ready...
Workspace "espw" (type root:organization) is ready to use.
Current workspace is "root:espw" (type root:organization).
Finished populating the espw with kubestellar apiexports
****************************************
Launching KubeStellar ...
****************************************
 mailbox-controller is running (log file: //kubestellar-logs/mailbox-controller-log.txt)
 where-resolver is running (log file: //kubestellar-logs/kubestellar-where-resolver-log.txt)
 placement translator is running (log file: //kubestellar-logs/placement-translator-log.txt)
****************************************
Finished launching KubeStellar ...
****************************************
Current workspace is "root".
Ready!
```

## Access **KubeStellar** service directly from the host without KUBECONFIG or executables

Since **kubectl**, **kcp** plugins, and **KubeStellar** executables are include in the **KubeStellar** container image we can operate KubeStellar directly from the host OS using `kubectl`, for example:

```shell
$ kubectl exec -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name}) -- kubectl ws tree
.
└── root
    ├── compute
    └── espw

$ kubectl exec -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name}) -- kubectl ws create imw
Workspace "imw" (type root:organization) created. Waiting for it to be ready...
Workspace "imw" (type root:organization) is ready to use.
```

## Access **KubeStellar** service from the host

In this case the host OS will need a copy of **kcp** `admin.kubeconfig`, **kcp** plugins, and **KubeStellar** binaries:

```shell

kubectl cp -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name}):/.kcp/admin.kubeconfig ./admin.kubeconfig

kubectl cp -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name}):/kcp-plugins .

ln -s kubectl-workspace kubectl-ws
ln -s kubectl-workspace kubectl-workspaces

kubectl cp -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name}):/kubestellar/bin .

chmod +x *

export KUBECONFIG=$PWD/admin.kubeconfig
export PATH=$PATH:$PWD

```

Setup port forwarding to the `kubestellar-server` pod:

```shell
kubectl port-forward -n kubestellar pod/$(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name}) 6443:6443 --address='0.0.0.0'
```

Edit the `admin.kubeconfig`, for each cluster entry:

1. add `insecure-skip-tls-verify: true`
2. change the server url to something like `https://127.0.0.1:6443` (or the public ip of the host OS)
3. remove the `certificate-authority-data` line

Now we can use use **KubeStellar** in the usual way:

```shell
$ kubectl ws tree
.
└── root
    ├── compute
    ├── espw
    │   └── 1787fno3dx2oin4h-mb-00b49918-368b-47c8-8782-fa82dffbdc23
    └── imw
```

## Access **KubeStellar** service from another pod in the same `kubestellar` namespace

Any pod in the same namespace can access **KubeStellar** by mounting the PVC with the `admin.kubeconfig`.
Obviously `kubectl`, **kcp** plugins, and **KubeStellar** exacutables are also needed.

In this example we create a `kubestellar-client` pod based on the same image of `kubestellar-server` since it already contains the required executables listed above:

```shell
$ kubectl apply -f kubestellar-client.yaml
deployment.apps/kubestellar-client created

$ kubectl get pods
NAME                                  READY   STATUS    RESTARTS   AGE
kubestellar-client-5dcd55b4c7-cvz6j   1/1     Running   0          32s
kubestellar-server-566f5cb54d-mmp8p   1/1     Running   0          58m
```

Now, let us log into the pod:

```shell
$ kubectl exec -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-client -o jsonpath={.items[0].metadata.name}) -it -- /bin/bash
```

From within the pod:

```shell
[kubestellar@kubestellar-client-7c7d46cf77-sk2d4 /]$ kubectl ws tree
.
└── root
    ├── compute
    ├── espw
    │   └── 1787fno3dx2oin4h-mb-00b49918-368b-47c8-8782-fa82dffbdc23
    └── imw
```
