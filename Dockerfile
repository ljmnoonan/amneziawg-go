FROM golang:1.24 as awg
WORKDIR /build

# These ARGs are automatically provided by buildx
ARG TARGETPLATFORM
ARG TARGETARCH

# Copy and download dependencies first to leverage Docker layer caching
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build a pure Go static binary for Linux.
# The binary contains runtime checks to handle differences when running on Android.
# This ensures the build process is identical for both amd64 and arm64.
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -v -o /build/amneziawg-go .

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
