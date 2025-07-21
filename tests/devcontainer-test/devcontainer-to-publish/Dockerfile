FROM mcr.microsoft.com/dotnet/sdk:8.0.412-noble-amd64

ENTRYPOINT ["/bin/bash", "-c", "mkdir -p /logs && echo \"CUSTOM_DEVCONTAINER: devcontainer-test-container\" > /logs/devcontainer.log && exec \"$@\"", "--"]
