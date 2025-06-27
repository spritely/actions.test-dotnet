#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../test-dotnet.sh"
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

@test "test-dotnet successfully runs passing tests and generates coverage report" {
    run "${SCRIPT_PATH}" "tests/sample-projects/basic/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "test-dotnet handles multiple test projects" {
    run "${SCRIPT_PATH}" "tests/sample-projects/multiple/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]

    # Verify output contains all project names
    [[ "$output" == *"TestProject.UnitTests"* ]]
    [[ "$output" == *"AnotherProject.UnitTests"* ]]
}

@test "test-dotnet handles different naming pattern" {
    run "${SCRIPT_PATH}" "tests/sample-projects/different-naming-pattern/**/*.Tests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "test-dotnet fails when compile is broken" {
    run "${SCRIPT_PATH}" "tests/sample-projects/broken-compile/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "test-dotnet fails when tests fail" {
    run "${SCRIPT_PATH}" "tests/sample-projects/failing-tests/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # Even with failing tests, a coverage report should be generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "test-dotnet fails when coverage collector is missing" {
    run "${SCRIPT_PATH}" "tests/sample-projects/missing-coverage-collector/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "test-dotnet fails when project is not a test project" {
    run "${SCRIPT_PATH}" "tests/sample-projects/non-test-project/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "test-dotnet handles no matching test projects" {
    run "${SCRIPT_PATH}" "tests/sample-projects/non-existent-tests/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}
