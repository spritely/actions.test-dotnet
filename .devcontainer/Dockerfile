# 1. List of all available tags: https://mcr.microsoft.com/product/dotnet/sdk/tags
# 2. Details about selecting a container image: https://github.com/dotnet/dotnet-docker/blob/main/README.sdk.md
# 3. Ubuntu releases: https://www.releases.ubuntu.com/
# 4. Information on dotnet versions: https://dotnet.microsoft.com/en-us/download/dotnet
# Also see:
# - .NET tagging policy: https://github.com/dotnet/dotnet-docker/blob/main/documentation/supported-tags.md
# - .NET image variants: https://github.com/dotnet/dotnet-docker/blob/main/documentation/image-variants.md

# Starting point for this file: https://github.com/devcontainers/images/blob/main/src/dotnet/.devcontainer/Dockerfile

# To find an image tag from #1:
# - Use the linux amd64 variant from #2
# - Choose latest long-term-support (LTS) version of Ubuntu from #3
# - Select the latest dotnet version from #4 that exists in #1
ARG VARIANT=8.0.407-noble-amd64
FROM mcr.microsoft.com/dotnet/sdk:${VARIANT}

# Clear this environment variable so xml docs from NuGet packages are unpackaged. The default dotnet/sdk image sets it to 'skip'.
# See https://github.com/dotnet/dotnet-docker/issues/2790
ENV NUGET_XMLDOC_MODE=

RUN apt-get update && apt-get install -y \
    bats \
    git \
    openssh-client \
    wget && \
    # The version of yq available in apt is very outdated so it must be manually installed
    # To find newer versions visit: https://github.com/mikefarah/yq/releases/
    wget https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
