FROM mcr.microsoft.com/dotnet/sdk:10.0.301-resolute-amd64@sha256:4265886564819acf37ee3510889c0f4600ac13eec1d70edb81ea471e44d435f0

ENTRYPOINT ["/bin/bash", "-c", "mkdir -p /logs && echo \"CUSTOM_DEVCONTAINER: devcontainer-test-container\" > /logs/devcontainer.log && exec \"$@\"", "--"]
