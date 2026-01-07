# Invoke as: docker build .

FROM debian:trixie-slim

ARG ZIG_VERSION=0.15.2
ARG ZIG_PUBKEY="RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U"

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        minisign \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Detect architecture at runtime and download Zig
RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
        x86_64) ZIG_ARCH="x86_64" ;; \
        aarch64) ZIG_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac; \
    ZIG_TARBALL="zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz"; \
    ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}"; \
    curl -fsSL -o "/tmp/${ZIG_TARBALL}" "${ZIG_URL}"; \
    curl -fsSL -o "/tmp/${ZIG_TARBALL}.minisig" "${ZIG_URL}.minisig"; \
    printf '%s\n%s\n' "untrusted comment: Zig release signing key" "${ZIG_PUBKEY}" > /tmp/zig.pub; \
    minisign -Vm "/tmp/${ZIG_TARBALL}" -p /tmp/zig.pub; \
    mkdir -p /opt/zig; \
    tar -xJf "/tmp/${ZIG_TARBALL}" -C /opt/zig --strip-components=1; \
    rm -rf /tmp/${ZIG_TARBALL} /tmp/${ZIG_TARBALL}.minisig /tmp/zig.pub

RUN useradd --system --uid 65532 --create-home --home-dir /home/build build
USER build
ENV PATH="/opt/zig:${PATH}"
WORKDIR /home/build

RUN zig version
