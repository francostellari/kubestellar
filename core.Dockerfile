###############################################################################
# Builder image
###############################################################################
FROM redhat/ubi9 AS builder

ENV sp_name="kcp"

ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM
ARG GIT_DIRTY=dirty

RUN groupadd kubestellar && useradd -g kubestellar kubestellar

WORKDIR /home/kubestellar

RUN mkdir -p ".${sp_name}" && \
    dnf install -y git golang jq procps && \
    go install github.com/mikefarah/yq/v4@v4.34.2 && \
    curl -SL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v1.25.3/bin/${TARGETPLATFORM}/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    curl -SL -o easy-rsa.tar.gz "https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.5/EasyRSA-3.1.5.tgz" && \
    got_hash=$(sha256sum easy-rsa.tar.gz  | awk '{ print $1 }') && \
    if [ "$got_hash" != 9fc6081d4927e68e9baef350e6b3010c7fb4f4a5c3e645ddac901081eb6adbb2 ]; then \
       echo "Got bad copy of EasyRSA-3.1.5.tgz" >&2 ; \
       exit 1; \
    fi && \
    mkdir easy-rsa && \
    tar -C easy-rsa -zxf easy-rsa.tar.gz --wildcards --strip-components=1 EasyRSA*/* && \
    rm easy-rsa.tar.gz && \
    curl -SL -o "${sp_name}.tar.gz" "https://github.com/${sp_name}-dev/${sp_name}/releases/download/v0.11.0/${sp_name}_0.11.0_${TARGETOS}_${TARGETARCH}.tar.gz" && \
    mkdir "${sp_name}" && \
    tar -C "${sp_name}" -zxf "${sp_name}.tar.gz" && \
    rm "${sp_name}.tar.gz" && \
    curl -SL -o "${sp_name}-plugins.tar.gz" "https://github.com/${sp_name}-dev/${sp_name}/releases/download/v0.11.0/kubectl-${sp_name}-plugin_0.11.0_${TARGETOS}_${TARGETARCH}.tar.gz" && \
    mkdir "${sp_name}-plugins" && \
    tar -C "${sp_name}-plugins" -zxf "${sp_name}-plugins.tar.gz" && \
    rm "${sp_name}-plugins.tar.gz" && \
    git config --global --add safe.directory /home/kubestellar && \
    mkdir -p bin && \
    mkdir -p scripts

RUN git clone https://github.com/waltforme/kube-bind.git && \
    pushd kube-bind && \
    mkdir bin && \
    IGNORE_GO_VERSION=1 go build -o ./bin/example-backend ./cmd/example-backend/main.go && \
    git checkout origin/syncmore && \
    IGNORE_GO_VERSION=1 go build -o ./bin/konnector ./cmd/konnector/main.go && \
    git checkout origin/autobind && \
    IGNORE_GO_VERSION=1 go build -o ./bin/kubectl-bind ./cmd/kubectl-bind/main.go && \
    export PATH=$(pwd)/bin:$PATH && \
    popd && \
    git clone https://github.com/dexidp/dex.git && \
    pushd dex && \
    IGNORE_GO_VERSION=1 make build && \
    popd

ENV PATH=$PATH:/root/go/bin

ADD cmd/             cmd/
ADD config/          config/
ADD hack/            hack/
ADD monitoring/      monitoring/
ADD pkg/             pkg/
ADD scripts/inner/   scripts/inner/
ADD scripts/overlap/ scripts/overlap/
ADD space-framework/ space-framework/
ADD test/            test/
ADD .git/            .git/
ADD .gitattributes Makefile Makefile.venv go.mod go.sum .

RUN make innerbuild GIT_DIRTY=$GIT_DIRTY IGNORE_GO_VERSION=yesplease

FROM redhat/ubi9

ENV sp_name="kcp"

WORKDIR /home/kubestellar

RUN dnf install -y jq procps && \
    dnf -y upgrade openssl && \
    groupadd kubestellar && \
    adduser -g kubestellar kubestellar && \
    mkdir -p ".${sp_name}"

# copy binaries from the builder image
COPY --from=builder /home/kubestellar/easy-rsa                           easy-rsa/
COPY --from=builder /root/go/bin                                         /usr/local/bin/
COPY --from=builder /usr/local/bin/kubectl                               /usr/local/bin/kubectl
COPY --from=builder /home/kubestellar/${sp_name}/bin                     ${sp_name}/bin/
COPY --from=builder /home/kubestellar/${sp_name}-plugins/bin             ${sp_name}/bin/
COPY --from=builder /home/kubestellar/bin                                bin/
COPY --from=builder /home/kubestellar/config                             config/
COPY --from=builder /home/kubestellar/kube-bind/bin                      kube-bind/bin/
COPY --from=builder /home/kubestellar/kube-bind/hack/dex-config-dev.yaml kube-bind/hack/dex-config-dev.yaml
COPY --from=builder /home/kubestellar/kube-bind/deploy/crd               kube-bind/deploy/crd
COPY --from=builder /home/kubestellar/dex/bin                            dex/bin/

# add entry script
ADD core-container/entry.sh entry.sh

RUN chown -R kubestellar:0 /home/kubestellar && \
    chmod -R g=u /home/kubestellar

# setup the environment variables
ENV PATH=/home/kubestellar/bin:/home/kubestellar/${sp_name}/bin:/home/kubestellar/kube-bind/bin:/home/kubestellar/dex/bin:/home/kubestellar/easy-rsa:$PATH
ENV KUBECONFIG=/home/kubestellar/.${sp_name}/admin.kubeconfig
ENV EXTERNAL_HOSTNAME=""
ENV EXTERNAL_PORT=""

# Switch the user
USER kubestellar

# start KubeStellar
CMD [ "/home/kubestellar/entry.sh" ]