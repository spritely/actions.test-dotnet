FROM mcr.microsoft.com/dotnet/sdk:10.0.201-noble-amd64@sha256:641ab8d0a499b924d685c6c5af45e6ecb2b42af6290fa399c8f858d3c1823829

ENTRYPOINT ["/bin/bash", "-c", "mkdir -p /logs && echo \"CUSTOM_DEVCONTAINER: devcontainer-test-container\" > /logs/devcontainer.log && exec \"$@\"", "--"]
