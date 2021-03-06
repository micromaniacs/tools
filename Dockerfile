ARG GOLANG_VERSION=1.15-alpine
ARG GOLANGCI_LINT_VERSION=v1.33.0
ARG MOCKGEN_VERSION=v1.4.4
ARG PROTOC_GEN_GO_VERSION=v1.4.3

FROM golang:$GOLANG_VERSION AS build

ARG GOLANGCI_LINT_VERSION
ARG MOCKGEN_VERSION
ARG PROTOC_GEN_GO_VERSION

ENV XDG_CACHE_HOME=/tmp/go-build \
    CGO_ENABLED=0 \
    GO111MODULE=on

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
        curl \
        git \
        make \
        protobuf \
        protobuf-dev \
        upx \
    # Formatting tools
    && go get mvdan.cc/gofumpt \
    && go get golang.org/x/tools/cmd/goimports \
    # Linter
    && curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin "$GOLANGCI_LINT_VERSION" \
    # Mocks generator
    && go get "github.com/golang/mock/mockgen@$MOCKGEN_VERSION" \
    # Protobuf code generators
    && go get "github.com/golang/protobuf/protoc-gen-go@$PROTOC_GEN_GO_VERSION" \
    && GO111MODULE=off go get -d "github.com/envoyproxy/protoc-gen-validate" \
    && cd "$GOPATH/src/github.com/envoyproxy/protoc-gen-validate" \
    && make build \
    && upx -9 \
        /go/bin/gofumpt \
        /go/bin/goimports \
        /go/bin/golangci-lint \
        /go/bin/mockgen \
        /go/bin/protoc-gen-go \
        /go/bin/protoc-gen-validate

FROM golang:$GOLANG_VERSION

COPY --from=build \
    /go/bin/gofumpt \
    /go/bin/goimports \
    /go/bin/golangci-lint \
    /go/bin/mockgen \
    /go/bin/protoc-gen-go \
    /go/bin/protoc-gen-validate \
    /bin/

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
        build-base \
        gcc \
        protobuf \
        protobuf-dev
