# Deploy **KubeStellar** service in a Kind cluster

Table of contests:
- [Deploy **KubeStellar** service in a Kind cluster](#deploy-kubestellar-service-in-a-kind-cluster)
  - [Deploy **KubeStellar** in a Kind cluster](#deploy-kubestellar-in-a-kind-cluster)
  - [Access **KubeStellar** service directly from the host without KUBECONFIG or executables](#access-kubestellar-service-directly-from-the-host-without-kubeconfig-or-executables)
  - [Access **KubeStellar** service from the host](#access-kubestellar-service-from-the-host)
  - [Access **KubeStellar** service from another pod in the same `kubestellar` namespace](#access-kubestellar-service-from-another-pod-in-the-same-kubestellar-namespace)

## Deploy **KubeStellar** in a Kind cluster

Create a **Kind** cluster with the `extraPortMappings` for ports `80` and `443`:

```shell
kind create cluster --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

Create an `nginx-ingress` with SSL passthrough using the YAML file [kind-nginx-ingress-with-SSL-passthrough.yaml](./kind-nginx-ingress-with-SSL-passthrough.yaml):

```shell
kubectl apply -f kind-nginx-ingress-with-SSL-passthrough.yaml
```

Wait for the ingress to be ready:

```shell
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

Deploy **KubeStellar** `stable` in a `kubestellar` namespace:

```shell
kubectl apply -f kubestellar-server.yaml
```

Wait for **KubeStellar** to be ready:

```shell
kubectl logs -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name})
```

```text
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

Add the **KubeStellar** ingress `kubestellar.svc.cluster.local` to the `/etc/hosts` files:

```text
127.0.0.1       kubestellar.svc.cluster.local
```

Edit the `admin.kubeconfig`, for each cluster entry:

1. add `insecure-skip-tls-verify: true`
2. change the server url to something like `https://kubestellar.svc.cluster.local`
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
Obviously `kubectl`, **kcp** plugins, and **KubeStellar** executables are also needed.

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
