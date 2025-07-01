# Use --platform=$BUILDPLATFORM to ensure this stage runs natively on the runner for speed.
# Go will then handle the cross-compilation.
FROM --platform=$BUILDPLATFORM golang:1.24 as builder

# These ARGs are automatically provided by buildx for cross-compilation
ARG TARGETPLATFORM
ARG TARGETARCH

WORKDIR /build

# Copy and download dependencies first to leverage Docker layer caching
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build a pure Go static binary for the target architecture.
# This avoids CGO and emulation issues, and is the most robust way to cross-compile.
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -ldflags="-s -w" -v -o /build/amneziawg-go .

FROM alpine:3.19
RUN apk --no-cache add iproute2 iptables bash wget unzip && \
    cd /usr/bin/ && \
    arch=$(uname -m) && \
    if [ "$arch" = "x86_64" ]; then arch="amd64"; fi && \
    if [ "$arch" = "aarch64" ]; then arch="arm64"; fi && \
    wget -q --show-progress -L "https://github.com/ljmnoonan/amneziawg-tools/releases/latest/download/alpine-3.19-amneziawg-tools-${arch}.zip" -O tools.zip && \
    unzip -j tools.zip && rm tools.zip && \
    chmod +x /usr/bin/awg /usr/bin/awg-quick && \
    ln -s /usr/bin/awg /usr/bin/wg && \
    ln -s /usr/bin/awg-quick /usr/bin/wg-quick
COPY --from=builder /build/amneziawg-go /usr/bin/amneziawg-go
