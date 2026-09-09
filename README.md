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
      - uses: actions/checkout@v6

      - uses: spritely/actions.test-dotnet@v0.3.0
        with:
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

      - uses: spritely/actions.test-dotnet@v0.3.0
        with:
          projectFile: "MyProject/MyProject.csproj"
          # Read devcontainers from here
          registryHost: ghcr.io
          registryUsername: ${{ github.actor }}
          registryPassword: ${{ github.token }}
```

## Inputs

| Name                | Required | Default                 | Description                                                            |
|---------------------|----------|-------------------------|------------------------------------------------------------------------|
| `githubToken`       | false    | `${{ github.token }}`   | The GitHub token to use to pull packages.                              |
| `projectFile`       | true     |                         | The main project file to build such as MyProject/MyProject.csproj.     |
| `unitTestProjects`  | false    | `**/*.UnitTests.csproj` | Glob for test projects.                                                |
| `coverageThreshold` | false    | `90`                    | Minimum coverage % to pass.                                            |
| `writeSummary`      | false    | `true`                  | Whether to write a summary of the test and coverage results to GitHub. |
| `registryHost`      | false    | `""`                    | Container registry hostname (for private DevContainer images).         |
| `registryUsername`  | false    | `""`                    | Container registry username.                                           |
| `registryPassword`  | false    | `""`                    | Container registry password or token.                                  |

## Outputs

| Name                   | Description                                   |
|------------------------|-----------------------------------------------|
| `coverageThresholdMet` | `true` if coverage ≥ threshold, else `false`. |
| `lineCoverage`         | Actual line coverage percentage (number only).|

## Test runners

`dotnet test` can drive test projects through two runners, and each one takes different options for code coverage and trx reports. The action detects which runner is active the same way the SDK does: when the `global.json` governing the repository contains

```json
{
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}
```

tests run on **Microsoft.Testing.Platform (MTP)**; otherwise they run on **VSTest**.

### VSTest (.NET 8, .NET 9, and .NET 10 without the `global.json` switch)

Coverage and trx are produced by data collectors, so each test project needs:

```xml
<PackageReference Include="coverlet.collector" Version="..." />
<PackageReference Include="Microsoft.NET.Test.Sdk" Version="..." />
```

### Microsoft.Testing.Platform (.NET 10 with the `global.json` switch)

`dotnet test` forwards its options straight to the test application, so coverage and trx are produced by MTP extensions that must be referenced by each test project:

```xml
<PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="..." />
<PackageReference Include="Microsoft.Testing.Extensions.TrxReport" Version="..." />
```

The extension versions must be built for the same Microsoft.Testing.Platform major as the test framework, otherwise the test application fails to start:

| Test framework                       | Microsoft.Testing.Platform | `Microsoft.Testing.Extensions.CodeCoverage` | `Microsoft.Testing.Extensions.TrxReport` |
|--------------------------------------|----------------------------|---------------------------------------------|------------------------------------------|
| `xunit.v3` 3.x (`xunit.v3.mtp-v1`)   | 1.x                        | 18.0.x                                      | 1.9.x                                    |
| `xunit.v3` 4.x (`xunit.v3.mtp-v2`)   | 2.x                        | 18.1 and later                              | 2.x                                      |

When a test project runs on MTP without these packages the action fails with a message naming the missing packages instead of the raw `Unknown option '--coverage'` output.

Coverage on MTP is configured through a [Microsoft Code Coverage settings file](https://learn.microsoft.com/visualstudio/test/customizing-code-coverage-analysis). The action always uses its own [`coverage.settings.xml`](coverage.settings.xml), which is equivalent to its VSTest coverlet configuration (auto-properties skipped, generated code and `*.pb.cs` / `*.grpc.cs` files excluded).

## Testing Strategy

### 1. Unit tests (`test-dotnet.bats`)

Validate core script logic locally in isolation. These tests are run for versions of dotnet 8, 9, and 10.

### 2. Workflow tests (`tests/*-test/`)

Verify full GitHub Action behavior using test container registries and package servers. Runs only in GitHub Action pipeline for testing overall workflow. These tests are targeted at the GitHub Actions workflow and not about the dotnet behavior so elected to not make test versions for each specific version of dotnet since the bats test already provide most of this coverage.

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

