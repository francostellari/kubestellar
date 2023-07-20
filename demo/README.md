# KubeStellar demo

## Create the kind clusters

```shell
kind create cluster --name center
kind create cluster --name edge

k --context kind-center get pods -A
k --context kind-edge   get pods -A
```

```shell
$ kubectl config get-contexts
CURRENT   NAME          CLUSTER       AUTHINFO      NAMESPACE
          kind-center   kind-center   kind-center
*         kind-edge     kind-edge     kind-edg
```

## Deploy KubeStellar core in `center` using Helm

Set the context to `kind-center`:

```shell
$ kubectl config use-context kind-center
Context "kind-center" modified.
```

Stand up KubeStellar with the Helm chart:

```shell
$ helm install kubestellar /vagrant/helm/kubestellar-chart
NAME: kubestellar
LAST DEPLOYED: Thu Jul 20 09:28:45 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

$ k get pods,pvc,service -n kubestellar
NAME                                      READY   STATUS    RESTARTS   AGE
pod/kubestellar-server-566f5cb54d-9gzmp   1/1     Running   0          106s

NAME                                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/kubestellar-pvc   Bound    pvc-5824f914-6f3d-427f-9b4a-af1c8ddbe3ae   1Mi        RWO            standard       106s

NAME                          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/kubestellar-service   ClusterIP   10.96.216.92   <none>        6443/TCP   106s
```

Enable port forwarding:

```shell
kubectl port-forward -n kubestellar pod/$(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name}) 6443:6443 --address='0.0.0.0'
```

Get **kcp** `admin.kubeconfig`:

```shell
kubectl cp -n kubestellar $(kubectl get pod -n kubestellar --selector=app=kubestellar-server -o jsonpath={.items[0].metadata.name}):/.kcp/admin.kubeconfig ./admin.kubeconfig
```

Edit the `admin.kubeconfig`, for each cluster entry:

1. add `insecure-skip-tls-verify: true`
2. change the server url to something like `https://127.0.0.1:6443` (or the public ip of the host OS)
3. remove the `certificate-authority-data` line

For example:

```yaml
- cluster:
    insecure-skip-tls-verify: true
#    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURNRENDQWhpZ0F3SUJBZ0lCQWpBTkJna3Foa2lHOXcwQkFRc0ZBREFqTVNFd0h3WURWUVFERE>    server: https://9.2.x.x:6443/clusters/root
  name: root
```

Then:

```shell
KUBECONFIG=$HOME/admin.kubeconfig k ws .
```

## Follow QuickStart steps

Create **IMW**:

```shell
$ KUBECONFIG=$HOME/admin.kubeconfig kubectl ws root
 create example-imw
Current workspace is "root".

$ KUBECONFIG=$HOME/admin.kubeconfig kubectl ws create example-imw
Workspace "example-imw" (type root:organization) created. Waiting for it to be ready...
Workspace "example-imw" (type root:organization) is ready to use.
```

Create WMW:

```shell
$ KUBECONFIG=$HOME/admin.kubeconfig kubectl ws root
Current workspace is "root".

$ KUBECONFIG=$HOME/admin.kubeconfig kubectl ws create my-org --enter
Workspace "my-org" (type root:organization) created. Waiting for it to be ready...
Workspace "my-org" (type root:organization) is ready to use.
Current workspace is "root:my-org" (type root:organization).

$ KUBECONFIG=$HOME/admin.kubeconfig kubectl kubestellar ensure wmw example-wmw
Current workspace is "root".
Current workspace is "root:my-org".
Workspace "example-wmw" (type root:universal) created. Waiting for it to be ready...
Workspace "example-wmw" (type root:universal) is ready to use.
Current workspace is "root:my-org:example-wmw" (type root:universal).
apibinding.apis.kcp.io/bind-espw created
apibinding.apis.kcp.io/bind-kubernetes created
apibinding.apis.kcp.io/bind-apps created
apibinding.apis.kcp.io/bind-autoscaling created
apibinding.apis.kcp.io/bind-batch created
apibinding.apis.kcp.io/bind-core.k8s.io created
apibinding.apis.kcp.io/bind-discovery.k8s.io created
apibinding.apis.kcp.io/bind-networking.k8s.io created
apibinding.apis.kcp.io/bind-policy created
apibinding.apis.kcp.io/bind-storage.k8s.io created
```

Onboard a cluster:

```shell
$ KUBECONFIG=$HOME/admin.kubeconfig kubectl ws root
Current workspace is "root".

$ KUBECONFIG=$HOME/admin.kubeconfig kubectl kubestellar prep-for-cluster --imw root:example-imw kind-edge env=prod -o - 2> /dev/null 1> syncer.yaml
```

Unfortunately the YAML will contain spurious output line at the beginning/end to be clean.
The YAML contains already the public address and no TLS.
Add `insecure-skip-tls-verify: true`

Apply the syncer YAML to the `kind-edge`

```shell
$ k --context kind-edge apply -f syncer.yaml
namespace/kubestellar-syncer-kind-edge-2bs8e4e4 created
serviceaccount/kubestellar-syncer-kind-edge-2bs8e4e4 created
secret/kubestellar-syncer-kind-edge-2bs8e4e4-token created
clusterrole.rbac.authorization.k8s.io/kubestellar-syncer-kind-edge-2bs8e4e4 created
clusterrolebinding.rbac.authorization.k8s.io/kubestellar-syncer-kind-edge-2bs8e4e4 created
secret/kubestellar-syncer-kind-edge-2bs8e4e4 created
deployment.apps/kubestellar-syncer-kind-edge-2bs8e4e4 created
```

Create EdgePlacement:

```shell
KUBECONFIG=$HOME/admin.kubeconfig kubectl ws root:my-org:example-wmw

KUBECONFIG=$HOME/admin.kubeconfig kubectl apply -f - <<EOF
apiVersion: edge.kcp.io/v1alpha1
kind: EdgePlacement
metadata:
  name: edge-placement-c
spec:
  locationSelectors:
  - matchLabels: {"env":"prod"}
  namespaceSelector:
    matchLabels: {"common":"si"}
  nonNamespacedObjects:
  - apiGroup: apis.kcp.io
    resources: [ "apibindings" ]
    resourceNames: [ "bind-kubernetes" ]
  upsync:
  - apiGroup: "group1.test"
    resources: ["sprockets", "flanges"]
    namespaces: ["orbital"]
    names: ["george", "cosmo"]
  - apiGroup: "group2.test"
    resources: ["cogs"]
    names: ["william"]
EOF
```

Apply the workload to the WMW:

```shell
KUBECONFIG=$HOME/admin.kubeconfig kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: commonstuff
  labels: {common: "si"}
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: commonstuff
  name: httpd-htdocs
data:
  index.html: |
    <!DOCTYPE html>
    <html>
      <body>
        This is a common web site.
      </body>
    </html>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: commonstuff
  name: commond
spec:
  selector: {matchLabels: {app: common} }
  template:
    metadata:
      labels: {app: common}
    spec:
      containers:
      - name: httpd
        image: library/httpd:2.4
        ports:
        - name: http
          containerPort: 80
          hostPort: 8081
          protocol: TCP
        volumeMounts:
        - name: htdocs
          readOnly: true
          mountPath: /usr/local/apache2/htdocs
      volumes:
      - name: htdocs
        configMap:
          name: httpd-htdocs
          optional: false
EOF
```

Check:

```shell
$ KUBECONFIG=$HOME/admin.kubeconfig kubectl get ns
NAME          STATUS   AGE
commonstuff   Active   65s
default       Active   33m

$ KUBECONFIG=$HOME/admin.kubeconfig kubectl get deployments -n commonstuff
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
commond   0/0     0            0           80s
```

```shell
$ k --context kind-edge get pods -n commonstuff
NAMESPACE                               NAME                                                     READY   STATUS    RESTARTS   AGE
commonstuff                             commond-7b5d7ddd77-q5wfj                                 1/1     Running   0          4m52s
```