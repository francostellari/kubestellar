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

espw_name="espw"

echo "Ensuring ESPW..."

kubectl ws root &> /dev/null

if kubectl get Workspace "$espw_name" &> /dev/null; then
    echo "ESPW workspace already exists -- using it:"
    kubectl ws "$espw_name"
else
    kubectl ws create "$espw_name" --enter
fi

kubectl apply -f "/home/kubestellar/config/exports"

echo "Finished populating the ESPW with KubeStellar APIExports."
