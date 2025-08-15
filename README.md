# actions.test-dotnet
Runs dotnet test on all unit test projects, collects code coverage, and reports test and coverage results.

## Usage Examples

### Minimal example that uses public docker hub based devcontainers

```yaml
name: Build & Test
on: [push, workflow_dispatch]

jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v3

      - uses: spritely/actions.test-dotnet@v0.2.0
        with:
          nugetAuthToken: ${{ secrets.NUGET_TOKEN }}
          projectFile: "MyProject/MyProject.csproj"
          unitTestProjects: "**/*.Tests.csproj" # Defaults to "**/*.UnitTests.csproj"
          coverageThreshold: 80 # Defaults to 90
```

### Building with devcontainer from private GitHub container registry

```yaml
name: Build & Test
on: [push, workflow_dispatch]

jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v3

      - uses: spritely/actions.test-dotnet@v0.2.0
        with:
          nugetAuthToken: ${{ secrets.NUGET_TOKEN }}
          projectFile: "MyProject/MyProject.csproj"
          # Read devcontainers from here
          registryHost: ghcr.io
          registryUsername: ${{ github.actor }}
          registryPassword: ${{ github.token }}
```

## Inputs

| Name                | Required | Default                         | Description                                                             |
|---------------------|:--------:|---------------------------------|-------------------------------------------------------------------------|
| `nugetAuthToken`    |   true   |                                 | The NuGet auth token for pulling packages.                              |
| `projectFile`       |   true   |                                 | The main project file to build such as MyProject/MyProject.csproj.     |
| `unitTestProjects`  |  false   | `**/*.UnitTests.csproj`         | Glob for test projects.                                                 |
| `coverageThreshold` |  false   | `90`                            | Minimum coverage % to pass.                                             |
| `writeSummary`      |  false   | `true`                          | Whether to write a summary of the test and coverage results to GitHub.  |
| `registryHost`      |  false   | `""`                            | Container registry hostname (for private DevContainer images).          |
| `registryUsername`  |  false   | `""`                            | Container registry username.                                            |
| `registryPassword`  |  false   | `""`                            | Container registry password or token.                                   |

## Outputs

| Name                   | Description                                   |
|------------------------|-----------------------------------------------|
| `coverageThresholdMet` | `true` if coverage ≥ threshold, else `false`. |
| `lineCoverage`         | Actual line coverage percentage (number only).|

## Testing Strategy

### 1. Unit tests (`test-dotnet.bats`)

Validate core script logic locally in isolation.

### 2. Workflow tests (`tests/*-test/`)

Verify full GitHub Action behavior using test container registries and package servers. Runs only in GitHub Action pipeline for testing overall workflow.

## DevContainer Decision

This action requires that each repository setup a DevContainer. This is more complex than just having dotnet available on the build server and running the packaging and publishing directory.

This decision is intentional to steer development to adopt DevContainers across all repositories, establishing a unified development approach and obtaining key DevContainer benefits including:

1. Zero-config onboarding
   - New contributors get working environment with:
     1. git clone
     2. Open project
     3. "Reopen in Container"

2. Consistency
   - Identical build environments for development and build server pipelines
   - Reduces "works on my machine" issues
   - Container-based workflows are more easily portable to alternative platforms like Dagger, GitLab, or Gitea.

3. Dependency management
   - Precise control over build tools, dependencies, and runtime versions without relying on GitHub runner configurations.

4. Multi-OS Support
   - Develop Linux-targeted software from Windows/macOS hosts

While this approach requires explicit DevContainer configuration in each repository, we believe the consistency and reliability benefits outweigh the initial setup cost. Repositories without DevContainers will need to either implement them or develop alternative packaging solutions.

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](/LICENSE) file for details.
