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

echo "< Starting Kubestellar container >-------------------------"

# Create the external kubeconfig
if ! ./create-admin.kubeconfig.sh ; then
    echo "ERROR: unable to create the admin.kubeconfig!" >&2
    exit 1
fi

# Wait for kcp to be ready
./wait-kcp-ready.sh

# Create the external kubeconfig:
# if ! ./ensure-kubestellar-secret.sh ; then
#     echo "ERROR: unable to create KubeStellar secret with the admin.kubeconfig!" >&2
#     exit 1
# fi

# Ensure key KubeStellar objects
# if ! ./ensure_root_compute_configd.sh ; then
#     echo "ERROR: unable to augment root:compute!" >&2
#     exit 1
# fi
# if ! ./ensure_espw.sh ; then
#     echo "ERROR: unable to ensure ESPW!" >&2
#     exit 1
# fi

echo Switching to "root"...
kubectl ws root

# Done, sleep forerver...
touch ready
echo "Ready!"
sleep infinity
