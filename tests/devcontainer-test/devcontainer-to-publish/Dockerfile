ARG VARIANT=8.0.407-noble-amd64
FROM mcr.microsoft.com/dotnet/sdk:${VARIANT}

ENTRYPOINT ["/bin/bash", "-c", "mkdir -p /logs && echo \"CUSTOM_DEVCONTAINER: devcontainer-test-container\" > /logs/devcontainer.log && exec \"$@\"", "--"]
