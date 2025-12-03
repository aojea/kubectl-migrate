FROM quay.io/buildah/stable:latest

# Install CRIU and utility tools
RUN dnf install -y criu jq \
    && dnf clean all

# Verify versions
RUN criu --version && buildah --version