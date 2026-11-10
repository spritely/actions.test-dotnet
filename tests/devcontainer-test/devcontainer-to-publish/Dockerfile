FROM mcr.microsoft.com/dotnet/sdk:10.0.404-resolute-amd64@sha256:98def70794aace6e412c41025c24b05f688fac840f0090564826819e0c9677b6

ENTRYPOINT ["/bin/bash", "-c", "mkdir -p /logs && echo \"CUSTOM_DEVCONTAINER: devcontainer-test-container\" > /logs/devcontainer.log && exec \"$@\"", "--"]
