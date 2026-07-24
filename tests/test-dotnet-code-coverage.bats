#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../test-dotnet.sh"

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
    run_script() {
        local version=$1
        local threshold=$2
        local project_folder="${3:-tests/sample-projects/half-covered}"
        local unit_test_projects="${4:-${project_folder}/**/*.UnitTests.csproj}"

        # Update ALL csproj files in the project folder to the target version
        update_project_version "$version" "${project_folder}/**/*.csproj"

        # Run the test script with coverage threshold (using the test project pattern)
        # The 'run' command sets $status and $output for the test to use
        COVERAGE_THRESHOLD="${threshold}" run "${SCRIPT_PATH}" "$unit_test_projects"

        # Restore ALL projects to net10.0 (default to match devcontainer)
        update_project_version "10.0" "${project_folder}/**/*.csproj"

        # Function returns 0 (success), test will check $status set by 'run' command
    }
}

teardown() {
    rm -rf "./covered-test-results"
}

teardown_file() {
    # The .NET SDK leaves a persistent Roslyn compiler server (VBCSCompiler) running to speed up
    # later builds. It inherits Bats' file descriptors, so if it outlives the suite Bats waits on it
    # and the final test hangs forever. "dotnet build-server shutdown" is the graceful way to stop it,
    # but in this non-root devcontainer that client hangs trying to reach the server (and PID 1 is
    # `sleep infinity`, which never reaps the resulting zombie). Force-kill the server so cleanup is
    # immediate and can never hang.
    pkill -f 'Roslyn/bincore/VBCSCompiler' 2>/dev/null || true
}

@test "[net8.0] test-dotnet fails when coverage is below threshold" {
    # Run with threshold of 80%
    run_script "8.0" 80

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
    run_script "9.0" 80

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
    run_script "10.0" 80

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
    run_script "8.0" 40

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
    run_script "9.0" 40

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
    run_script "10.0" 40

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
    run_script "8.0" 50

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
    run_script "9.0" 50

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
    run_script "10.0" 50

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
    run_script "8.0" 80 "tests/sample-projects/basic"
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
    run_script "9.0" 80 "tests/sample-projects/basic"
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
    run_script "10.0" 80 "tests/sample-projects/basic"
    [ "$status" -eq 0 ]

    # Verify no coverage report was generated or processed
    [[ ! "$output" == *"Line coverage:"* ]]
    [[ ! "$output" == *"Coverage threshold met"* ]]
    [[ ! "$output" == *"Code coverage must be at least"* ]]

    # Check that the file doesn't contain threshold information
    run grep "Coverage Threshold" "./covered-test-results/reports/SummaryGithub.md"
    [ "$status" -ne 0 ]
}
