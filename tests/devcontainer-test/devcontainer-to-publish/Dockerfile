FROM mcr.microsoft.com/dotnet/sdk:10.0.302-resolute-amd64@sha256:303563b156b9cccfb5f5316d18088d40e9073ab7fb47de76349c077eefdedbcf

ENTRYPOINT ["/bin/bash", "-c", "mkdir -p /logs && echo \"CUSTOM_DEVCONTAINER: devcontainer-test-container\" > /logs/devcontainer.log && exec \"$@\"", "--"]
