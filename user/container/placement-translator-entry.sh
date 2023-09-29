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

echo "< Starting Kubestellar placement-translator >-------------------------"

# Create the external kubeconfig
if ! ./create-admin.kubeconfig.sh ; then
    echo "ERROR: unable to create the admin.kubeconfig!" >&2
    exit 1
fi

# Wait for kcp to be ready
./wait-kcp-ready.sh

if [ "$VERBOSITY" == "" ]; then
    VERBOSITY="2"
fi

if ! placement-translator --allclusters-context  "system:admin" -v=${VERBOSITY} ; then
    echo "ERROR: unable to start mailbox-controller!" >&2
    exit 1
fi
