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

ADMIN_KUBECONFIG=$KUBECONFIG
KUBECONFIG=

echo "Creating the admin.kubeconfig..."

echo "Getting kcp route..."
EXTERNAL_HOSTNAME=$(kubectl get route kcp-front-proxy -o yaml -o jsonpath={.spec.host} 2> /dev/null)
echo "EXTERNAL_HOSTNAME=${EXTERNAL_HOSTNAME}"
if [ "$EXTERNAL_HOSTNAME" == "" ] ; then
  echo "ERROR: unable to determine kcp route!" >&2
  exit 1
fi

# echo " Retrieving kcp certificates from kcp secrets..."
# while [ "$(kubectl get secret kcp-front-proxy-cert -o=jsonpath='{.data.tls\.crt}')" == "" ] ; do
#     sleep 5
# done
# kubectl get secret kcp-front-proxy-cert -o=jsonpath='{.data.tls\.crt}' | base64 -d > ca.crt
# while [ "$(kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.crt}')" == "" ] ; do
#     sleep 5
# done
# kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.crt}' | base64 -d > client.crt
# while [ "$(kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.key}')" == "" ] ; do
#     sleep 5
# done
# kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.key}' | base64 -d > client.key
# chmod 600 client.crt client.key

echo "Assembling the admin.kubeconfig..."
kubectl --kubeconfig=${ADMIN_KUBECONFIG} config set-cluster base \
    --server https://${EXTERNAL_HOSTNAME}:443  \
    --certificate-authority=kcp-front-proxy-cert/ca.crt \
    --embed-certs
kubectl --kubeconfig=${ADMIN_KUBECONFIG} config set-cluster root \
    --server https://${EXTERNAL_HOSTNAME}:443/clusters/root \
    --certificate-authority=kcp-front-proxy-cert/ca.crt \
    --embed-certs
kubectl --kubeconfig=${ADMIN_KUBECONFIG} config set-credentials kcp-admin \
    --client-certificate=cluster-admin-client-cert/client.crt \
    --client-key=cluster-admin-client-cert/client.key \
    --embed-certs
kubectl --kubeconfig=${ADMIN_KUBECONFIG} config set-context base --cluster=base --user=kcp-admin
kubectl --kubeconfig=${ADMIN_KUBECONFIG} config set-context root --cluster=root --user=kcp-admin
kubectl --kubeconfig=${ADMIN_KUBECONFIG} config use-context root

echo "KUBECONFIG=${ADMIN_KUBECONFIG}"