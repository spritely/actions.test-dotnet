FROM mcr.microsoft.com/dotnet/sdk:10.0.101-noble-amd64@sha256:ab41a603bcdce28563e4cca6b9f010c3a8663eea9a0020d7591a180c8f6a81ca

ENTRYPOINT ["/bin/bash", "-c", "mkdir -p /logs && echo \"CUSTOM_DEVCONTAINER: devcontainer-test-container\" > /logs/devcontainer.log && exec \"$@\"", "--"]
