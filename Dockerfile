FROM golang:1.24 as awg
WORKDIR /build

# These ARGs are automatically provided by buildx
ARG TARGETPLATFORM
ARG TARGETARCH

# Copy and download dependencies first to leverage Docker layer caching
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build a pure Go static binary.
# When the target architecture is arm64, we compile for GOOS=android, as this
# binary is intended to be run on an Android device. For all other architectures,
# we compile for GOOS=linux. This ensures the correct build tags are used.
RUN if [ "$TARGETARCH" = "arm64" ]; then CGO_ENABLED=0 GOOS=android go build -ldflags="-s -w" -v -o /build/amneziawg-go .; \
    else CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -v -o /build/amneziawg-go .; fi

FROM alpine:3.19
ARG AWGTOOLS_RELEASE="1.0.20241018"
RUN apk --no-cache add iproute2 iptables bash && \
    cd /usr/bin/ && \
    wget https://github.com/amnezia-vpn/amneziawg-tools/releases/download/v${AWGTOOLS_RELEASE}/alpine-3.19-amneziawg-tools.zip && \
    unzip -j alpine-3.19-amneziawg-tools.zip && rm alpine-3.19-amneziawg-tools.zip && \
    chmod +x /usr/bin/awg /usr/bin/awg-quick && \
    ln -s /usr/bin/awg /usr/bin/wg && \
    ln -s /usr/bin/awg-quick /usr/bin/wg-quick
COPY --from=awg /build/amneziawg-go /usr/bin/amneziawg-go
