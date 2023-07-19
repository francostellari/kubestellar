# KubeStellar Helm charts

Table of contents:
- [KubeStellar Helm charts](#kubestellar-helm-charts)
  - [Install Helm](#install-helm)
  - [First time only, create an empty `kubestellar-chart`](#first-time-only-create-an-empty-kubestellar-chart)
  - [Validate the chart](#validate-the-chart)
  - [Deploy **KubeStellar** using the `kubestellar-chart`](#deploy-kubestellar-using-the-kubestellar-chart)
  - [References](#references)

## Install Helm

```shell
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install -y helm
```

## First time only, create an empty `kubestellar-chart`

```shell
helm create kubestellar-chart
cd /kubestellar-chart
```

## Validate the chart

Check that the cart is validL

```shell
helm lint .
```

Look at the deployment YAML:

```shell
helm template .
```

## Deploy **KubeStellar** using the `kubestellar-chart`

```shell
$ cd /kubestellar-chart

$ helm install kubestellar .
NAME: kubestellar
LAST DEPLOYED: Wed Jul 19 15:06:18 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

```shell
$ helm list
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
kubestellar     default         1               2023-07-19 15:06:18.980417619 -0400 EDT deployed        kubestellar-chart-0.1.0 v0.4.0

$ k get pods -n kubestellar
NAME                                  READY   STATUS    RESTARTS   AGE
kubestellar-server-566f5cb54d-lc4xs   1/1     Running   0          71s
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

## References

- https://devopscube.com/create-helm-chart/ --> https://github.com/techiescamp/helm-tutorial
