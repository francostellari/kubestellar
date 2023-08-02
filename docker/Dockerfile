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

###############################################################################
# Builder image
###############################################################################
FROM redhat/ubi9 AS builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM
ARG KUBESTELLAR_VERSION

WORKDIR /

# Download YQ
RUN curl -SL -o yq "https://github.com/mikefarah/yq/releases/latest/download/yq_${TARGETOS}_${TARGETARCH}" && \
    chmod +x yq

# Download kubectl binaries
RUN curl -SL -o kubectl "https://dl.k8s.io/release/v1.25.3/bin/${TARGETPLATFORM}/kubectl" && \
    chmod +x kubectl

# Download EasyRSA
RUN curl -SL -o easy-rsa.tar.gz "https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.5/EasyRSA-3.1.5.tgz" && \
    mkdir easy-rsa && \
    tar -C easy-rsa -zxf easy-rsa.tar.gz --wildcards --strip-components=1 EasyRSA*/*

# Download kcp binaries
RUN curl -SL -o kcp.tar.gz "https://github.com/kcp-dev/kcp/releases/download/v0.11.0/kcp_0.11.0_${TARGETOS}_${TARGETARCH}.tar.gz" && \
    mkdir kcp && \
    tar -C kcp -zxf kcp.tar.gz

# Download kcp plugins
RUN curl -SL -o kcp-plugins.tar.gz "https://github.com/kcp-dev/kcp/releases/download/v0.11.0/kubectl-kcp-plugin_0.11.0_${TARGETOS}_${TARGETARCH}.tar.gz" && \
    mkdir kcp-plugins && \
    tar -C kcp-plugins -zxf kcp-plugins.tar.gz

# Download KubeStellar binaries
RUN curl -SL -o kubestellar.tar.gz "https://github.com/kubestellar/kubestellar/releases/download/${KUBESTELLAR_VERSION}/kubestellar_${KUBESTELLAR_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz" && \
    mkdir kubestellar && \
    tar -C kubestellar -zxf kubestellar.tar.gz


###############################################################################
# KubeStellar image
###############################################################################
FROM redhat/ubi9

# Install requirements (for running inside the container)
RUN dnf install -y jq procps && \
    groupadd kubestellar && \
    adduser -g kubestellar kubestellar && \
    mkdir -p /kubestellar/home/kubestellar-logs && \
    chown -R kubestellar:kubestellar /kubestellar && \
    chgrp -R 0 /kubestellar && \
    chmod -R g=u /kubestellar

# Copy binaries from the builder image
COPY --from=builder /kubectl     /usr/local/bin/kubectl
COPY --from=builder /yq          /usr/local/bin/yq
COPY --from=builder /kcp         /kubestellar/kcp
COPY --from=builder /kcp-plugins /kubestellar/kcp-plugins
COPY --from=builder /kubestellar /kubestellar/kubestellar
COPY --from=builder /easy-rsa    /kubestellar/easy-rsa

# Add entry script
ADD entry.sh                     /kubestellar/entry.sh
ADD tls-scripts                  /kubestellar/tls-scripts
ADD syncer                       /kubestellar/kubestellar/bin

# List volumes of ineterest
VOLUME [ "/kubestellar/home/.kcp" , "/kubestellar/home/kubestellar-logs" , "/kubestellar/kcp" , "/kubestellar/kcp-plugins" , "/kubestellar/kubestellar" ]

# Setup the environment variables
ENV PATH=$PATH:/kubestellar/easy-rsa:/kubestellar/kcp/bin:/kubestellar/kcp-plugins/bin:/kubestellar/kubestellar/bin:/kubestellar/tls-scripts
ENV KUBECONFIG=/kubestellar/home/.kcp/admin.kubeconfig
ENV EXTERNAL_HOSTNAME=""
ENV EXTERNAL_PORT=""
ENV SECRET_NAMESPACES=""

# Switch the user
USER kubestellar
WORKDIR /kubestellar/home

# start KubeStellar
CMD [ "/kubestellar/entry.sh" ]
