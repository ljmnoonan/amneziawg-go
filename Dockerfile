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
ARG AWGTOOLS_RELEASE="1.0.20241018"
RUN apk --no-cache add iproute2 iptables bash && \
    cd /usr/bin/ && \
    wget https://github.com/amnezia-vpn/amneziawg-tools/releases/download/v${AWGTOOLS_RELEASE}/alpine-3.19-amneziawg-tools.zip && \
    unzip -j alpine-3.19-amneziawg-tools.zip && rm alpine-3.19-amneziawg-tools.zip && \
    chmod +x /usr/bin/awg /usr/bin/awg-quick && \
    ln -s /usr/bin/awg /usr/bin/wg && \
    ln -s /usr/bin/awg-quick /usr/bin/wg-quick
COPY --from=builder /build/amneziawg-go /usr/bin/amneziawg-go
