#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../test-dotnet.sh"
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

# Helper function to run test with specific .NET version
run_script() {
    local version=$1
    local project_folder=$2
    local test_project_pattern=$3

    # Update ALL csproj files in the project folder to the target version
    update_project_version "$version" "${project_folder}/**/*.csproj"

    # Run the test script (using the test project pattern)
    # The 'run' command sets $status and $output for the test to use
    run "${SCRIPT_PATH}" "$test_project_pattern"

    # Restore ALL projects to net10.0 (default to match devcontainer)
    update_project_version "10.0" "${project_folder}/**/*.csproj"

    # Function returns 0 (success), test will check $status set by 'run' command
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

@test "[net8.0] test-dotnet successfully runs passing tests and generates coverage report" {
    run_script "8.0" "tests/sample-projects/basic" "tests/sample-projects/basic/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net9.0] test-dotnet successfully runs passing tests and generates coverage report" {
    run_script "9.0" "tests/sample-projects/basic" "tests/sample-projects/basic/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net10.0] test-dotnet successfully runs passing tests and generates coverage report" {
    run_script "10.0" "tests/sample-projects/basic" "tests/sample-projects/basic/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net8.0] test-dotnet handles multiple test projects" {
    run_script "8.0" "tests/sample-projects/multiple" "tests/sample-projects/multiple/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]

    # Verify output contains all project names
    [[ "$output" == *"TestProject.UnitTests"* ]]
    [[ "$output" == *"AnotherProject.UnitTests"* ]]
}

@test "[net9.0] test-dotnet handles multiple test projects" {
    run_script "9.0" "tests/sample-projects/multiple" "tests/sample-projects/multiple/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]

    # Verify output contains all project names
    [[ "$output" == *"TestProject.UnitTests"* ]]
    [[ "$output" == *"AnotherProject.UnitTests"* ]]
}

@test "[net10.0] test-dotnet handles multiple test projects" {
    run_script "10.0" "tests/sample-projects/multiple" "tests/sample-projects/multiple/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]

    # Verify output contains all project names
    [[ "$output" == *"TestProject.UnitTests"* ]]
    [[ "$output" == *"AnotherProject.UnitTests"* ]]
}

@test "[net8.0] test-dotnet handles different naming pattern" {
    run_script "8.0" "tests/sample-projects/different-naming-pattern" "tests/sample-projects/different-naming-pattern/**/*.Tests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net9.0] test-dotnet handles different naming pattern" {
    run_script "9.0" "tests/sample-projects/different-naming-pattern" "tests/sample-projects/different-naming-pattern/**/*.Tests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net10.0] test-dotnet handles different naming pattern" {
    run_script "10.0" "tests/sample-projects/different-naming-pattern" "tests/sample-projects/different-naming-pattern/**/*.Tests.csproj"

    [ "$status" -eq 0 ]

    # Check that the coverage report was generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net8.0] test-dotnet fails when compile is broken" {
    run_script "8.0" "tests/sample-projects/broken-compile" "tests/sample-projects/broken-compile/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net9.0] test-dotnet fails when compile is broken" {
    run_script "9.0" "tests/sample-projects/broken-compile" "tests/sample-projects/broken-compile/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net10.0] test-dotnet fails when compile is broken" {
    run_script "10.0" "tests/sample-projects/broken-compile" "tests/sample-projects/broken-compile/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net8.0] test-dotnet fails when tests fail" {
    run_script "8.0" "tests/sample-projects/failing-tests" "tests/sample-projects/failing-tests/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # Even with failing tests, a coverage report should be generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net9.0] test-dotnet fails when tests fail" {
    run_script "9.0" "tests/sample-projects/failing-tests" "tests/sample-projects/failing-tests/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # Even with failing tests, a coverage report should be generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net10.0] test-dotnet fails when tests fail" {
    run_script "10.0" "tests/sample-projects/failing-tests" "tests/sample-projects/failing-tests/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # Even with failing tests, a coverage report should be generated
    [ -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net8.0] test-dotnet fails when coverage collector is missing" {
    run_script "8.0" "tests/sample-projects/missing-coverage-collector" "tests/sample-projects/missing-coverage-collector/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net9.0] test-dotnet fails when coverage collector is missing" {
    run_script "9.0" "tests/sample-projects/missing-coverage-collector" "tests/sample-projects/missing-coverage-collector/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net10.0] test-dotnet fails when coverage collector is missing" {
    run_script "10.0" "tests/sample-projects/missing-coverage-collector" "tests/sample-projects/missing-coverage-collector/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net8.0] test-dotnet fails when project is not a test project" {
    run_script "8.0" "tests/sample-projects/non-test-project" "tests/sample-projects/non-test-project/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net9.0] test-dotnet fails when project is not a test project" {
    run_script "9.0" "tests/sample-projects/non-test-project" "tests/sample-projects/non-test-project/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net10.0] test-dotnet fails when project is not a test project" {
    run_script "10.0" "tests/sample-projects/non-test-project" "tests/sample-projects/non-test-project/**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net8.0] test-dotnet handles no matching test projects" {
    run_script "8.0" "tests/sample-projects/non-existent-tests" "tests/sample-projects/non-existent-tests/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net9.0] test-dotnet handles no matching test projects" {
    run_script "9.0" "tests/sample-projects/non-existent-tests" "tests/sample-projects/non-existent-tests/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}

@test "[net10.0] test-dotnet handles no matching test projects" {
    run_script "10.0" "tests/sample-projects/non-existent-tests" "tests/sample-projects/non-existent-tests/**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # No coverage report should be generated
    [ ! -f "./covered-test-results/reports/SummaryGithub.md" ]
}
