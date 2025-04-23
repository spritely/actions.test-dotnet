#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../test-dotnet.sh"

    run_script() {
        unit_test_projects="${2:-tests/sample-projects/half-covered/**/*.UnitTests.csproj}"
        COVERAGE_THRESHOLD="${1}" run "${SCRIPT_PATH}" $unit_test_projects
    }
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

@test "test-dotnet fails when coverage is below threshold" {
    # Run with threshold of 80%
    run_script 80

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

@test "test-dotnet succeeds when coverage meets threshold" {
    # Run with threshold of 40%
    run_script 40

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

@test "test-dotnet succeeds with exact threshold match" {
    # Run with threshold of 50%
    run_script 50

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

@test "test-dotnet succeeds when no coverage report generated" {
    run_script 80 "tests/sample-projects/basic/**/*.UnitTests.csproj"
    [ "$status" -eq 0 ]

    # Verify no coverage report was generated or processed
    [[ ! "$output" == *"Line coverage:"* ]]
    [[ ! "$output" == *"Coverage threshold met"* ]]
    [[ ! "$output" == *"Code coverage must be at least"* ]]

    # Check that the file doesn't contain threshold information
    run grep "Coverage Threshold" "./covered-test-results/reports/SummaryGithub.md"
    [ "$status" -ne 0 ]
}
