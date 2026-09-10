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

## Requirements

Tests run through **Microsoft.Testing.Platform (MTP)**, the `dotnet test` mode of the .NET 10 SDK in which the options are forwarded straight to the test application. VSTest is not supported.

### 1. Enable MTP in `global.json`

The SDK switches `dotnet test` to MTP from the `global.json` governing the repository:

```json
{
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}
```

Without it `dotnet test` runs through VSTest and rejects the options the action passes.

### 2. Reference the MTP extensions in each test project

Code coverage and trx reports are produced by MTP extensions, so each test project needs:

```xml
<PackageReference Include="coverlet.MTP" Version="..." />
<PackageReference Include="Microsoft.Testing.Extensions.TrxReport" Version="..." />
```

`coverlet.MTP` requires Microsoft.Testing.Platform 2.0 or later, so the test framework must be built for that major: `xunit.v3` 4.x (`xunit.v3.mtp-v2`), MSTest 3.x or NUnit with its MTP adapter. `xunit.v3` 3.x targets Microsoft.Testing.Platform 1.x and cannot be used. `Microsoft.Testing.Extensions.TrxReport` must be a 2.x version for the same reason.

When a test project lacks these packages the test application rejects `--coverlet` / `--report-trx` and the run fails with a non-zero exit code.

### Coverage settings

The action runs each test project with the [coverlet.MTP](https://learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-code-coverage#coverlet) command line, which keeps the configuration the action used with VSTest:

- `--coverlet-output-format cobertura`
- `--coverlet-skip-auto-props`
- `--coverlet-exclude-by-attribute GeneratedCodeAttribute`
- `--coverlet-exclude-by-file "**/*.pb.cs"` and `"**/*.grpc.cs"`

Every test project writes to `covered-test-results/`; `--coverlet-file-prefix` is set to the project name so coverage files are `<Project>.coverage.cobertura.xml` and never collide. The test assembly itself is never instrumented (it is the Microsoft.Testing.Platform controller process).

## Testing Strategy

### 1. Unit tests (`test-dotnet.bats`)

Validate core script logic locally in isolation. These tests are run for target frameworks net8.0, net9.0 and net10.0 (all driven by the .NET 10 SDK, which is where MTP mode of `dotnet test` lives). The repository's own [`global.json`](global.json) enables MTP for every sample project.

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

