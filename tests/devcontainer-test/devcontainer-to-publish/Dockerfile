FROM mcr.microsoft.com/dotnet/sdk:10.0.404-resolute-amd64@sha256:4e3dadedb785d05aefed023d79434a3c7d980172824c6d50fcddffd27ec24530

ENTRYPOINT ["/bin/bash", "-c", "mkdir -p /logs && echo \"CUSTOM_DEVCONTAINER: devcontainer-test-container\" > /logs/devcontainer.log && exec \"$@\"", "--"]
