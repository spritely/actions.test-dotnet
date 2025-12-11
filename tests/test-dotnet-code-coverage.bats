#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../test-dotnet.sh"

    run_script() {
        unit_test_projects="${2:-tests/sample-projects/half-covered/**/*.UnitTests.csproj}"
        COVERAGE_THRESHOLD="${1}" run "${SCRIPT_PATH}" $unit_test_projects
    }
}

# Helper function to update .NET version in specific csproj files
update_project_version() {
    local version=$1
    local project_pattern=$2

    # Find all csproj files matching the pattern and update their TargetFramework
    while IFS= read -r csproj_file; do
        if [ -f "$csproj_file" ]; then
            sed -i "s|<TargetFramework>net[0-9.]*</TargetFramework>|<TargetFramework>net${version}</TargetFramework>|g" "$csproj_file"
        fi
    done < <(find . -type f -iwholename "*$project_pattern")
}

# Helper function to run test with specific .NET version and coverage threshold
run_script_with_version() {
    local version=$1
    local threshold=$2
    local project_pattern=$3

    # Update the specific csproj files to the target version
    update_project_version "$version" "$project_pattern"

    # Run the test script with coverage threshold
    # The 'run' command sets $status and $output for the test to use
    COVERAGE_THRESHOLD="${threshold}" run "${SCRIPT_PATH}" "$project_pattern"

    # Restore to net10.0 (default to match devcontainer)
    update_project_version "10.0" "$project_pattern"

    # Function returns 0 (success), test will check $status set by 'run' command
}

teardown() {
    rm -rf "./covered-test-results"
}

teardown_file() {
    # The .NET SDK keeps a background build server (VBCSCompiler) running to speed up subsequent builds.
    # This process isn't automatically terminated after the script runs.
    # When you source the script in Bats, any child processes become subprocesses of the Bats test runner.
    # Bats waits for all subprocesses to exit before completing and thus the last test hangs and never exits.
    # "dotnet build-server shutdown" gracefully terminates the Razor build server, the VB/C# compiler server,
    # and the MSBuild server.
    dotnet build-server shutdown
}

@test "[net8.0] test-dotnet fails when coverage is below threshold" {
    # Run with threshold of 80%
    run_script_with_version "8.0" 80

    [ "$status" -eq 1 ]

    # Check output message
    [[ "$output" == *"❌ Code coverage must be at least 80%, but was 50%"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 80%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"❌ **Code coverage must be at least 80%, but was 50%**"* ]]
}

@test "[net9.0] test-dotnet fails when coverage is below threshold" {
    # Run with threshold of 80%
    run_script_with_version "9.0" 80

    [ "$status" -eq 1 ]

    # Check output message
    [[ "$output" == *"❌ Code coverage must be at least 80%, but was 50%"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 80%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"❌ **Code coverage must be at least 80%, but was 50%**"* ]]
}

@test "[net10.0] test-dotnet fails when coverage is below threshold" {
    # Run with threshold of 80%
    run_script_with_version "10.0" 80

    [ "$status" -eq 1 ]

    # Check output message
    [[ "$output" == *"❌ Code coverage must be at least 80%, but was 50%"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 80%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"❌ **Code coverage must be at least 80%, but was 50%**"* ]]
}

@test "[net8.0] test-dotnet succeeds when coverage meets threshold" {
    # Run with threshold of 40%
    run_script_with_version "8.0" 40

    [ "$status" -eq 0 ]

    # Check output message
    [[ "$output" == *"✅ Coverage threshold met (50% >= 40%)"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 40%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"✅ **Coverage threshold met (50% >= 40%)**"* ]]
}

@test "[net9.0] test-dotnet succeeds when coverage meets threshold" {
    # Run with threshold of 40%
    run_script_with_version "9.0" 40

    [ "$status" -eq 0 ]

    # Check output message
    [[ "$output" == *"✅ Coverage threshold met (50% >= 40%)"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 40%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"✅ **Coverage threshold met (50% >= 40%)**"* ]]
}

@test "[net10.0] test-dotnet succeeds when coverage meets threshold" {
    # Run with threshold of 40%
    run_script_with_version "10.0" 40

    [ "$status" -eq 0 ]

    # Check output message
    [[ "$output" == *"✅ Coverage threshold met (50% >= 40%)"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 40%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"✅ **Coverage threshold met (50% >= 40%)**"* ]]
}

@test "[net8.0] test-dotnet succeeds with exact threshold match" {
    # Run with threshold of 50%
    run_script_with_version "8.0" 50

    [ "$status" -eq 0 ]

    # Check output message
    [[ "$output" == *"✅ Coverage threshold met (50% >= 50%)"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 50%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"✅ **Coverage threshold met (50% >= 50%)**"* ]]
}

@test "[net9.0] test-dotnet succeeds with exact threshold match" {
    # Run with threshold of 50%
    run_script_with_version "9.0" 50

    [ "$status" -eq 0 ]

    # Check output message
    [[ "$output" == *"✅ Coverage threshold met (50% >= 50%)"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 50%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"✅ **Coverage threshold met (50% >= 50%)**"* ]]
}

@test "[net10.0] test-dotnet succeeds with exact threshold match" {
    # Run with threshold of 50%
    run_script_with_version "10.0" 50

    [ "$status" -eq 0 ]

    # Check output message
    [[ "$output" == *"✅ Coverage threshold met (50% >= 50%)"* ]]

    # Check report
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
    run cat "./covered-test-results/reports/SummaryGithub.md"
    [[ "$output" == *"Required minimum: 50%"* ]]
    [[ "$output" == *"Actual coverage: 50%"* ]]
    [[ "$output" == *"✅ **Coverage threshold met (50% >= 50%)**"* ]]
}

@test "[net8.0] test-dotnet succeeds when no coverage report generated" {
    run_script_with_version "8.0" 80 "tests/sample-projects/basic/**/*.UnitTests.csproj"
    [ "$status" -eq 0 ]

    # Verify no coverage report was generated or processed
    [[ ! "$output" == *"Line coverage:"* ]]
    [[ ! "$output" == *"Coverage threshold met"* ]]
    [[ ! "$output" == *"Code coverage must be at least"* ]]

    # Check that the file doesn't contain threshold information
    run grep "Coverage Threshold" "./covered-test-results/reports/SummaryGithub.md"
    [ "$status" -ne 0 ]
}

@test "[net9.0] test-dotnet succeeds when no coverage report generated" {
    run_script_with_version "9.0" 80 "tests/sample-projects/basic/**/*.UnitTests.csproj"
    [ "$status" -eq 0 ]

    # Verify no coverage report was generated or processed
    [[ ! "$output" == *"Line coverage:"* ]]
    [[ ! "$output" == *"Coverage threshold met"* ]]
    [[ ! "$output" == *"Code coverage must be at least"* ]]

    # Check that the file doesn't contain threshold information
    run grep "Coverage Threshold" "./covered-test-results/reports/SummaryGithub.md"
    [ "$status" -ne 0 ]
}

@test "[net10.0] test-dotnet succeeds when no coverage report generated" {
    run_script_with_version "10.0" 80 "tests/sample-projects/basic/**/*.UnitTests.csproj"
    [ "$status" -eq 0 ]

    # Verify no coverage report was generated or processed
    [[ ! "$output" == *"Line coverage:"* ]]
    [[ ! "$output" == *"Coverage threshold met"* ]]
    [[ ! "$output" == *"Code coverage must be at least"* ]]

    # Check that the file doesn't contain threshold information
    run grep "Coverage Threshold" "./covered-test-results/reports/SummaryGithub.md"
    [ "$status" -ne 0 ]
}
