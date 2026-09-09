#!/usr/bin/env bats

# Microsoft.Testing.Platform (MTP) runner tests.
#
# The SDK switches `dotnet test` to MTP through the nearest global.json, which it resolves from the
# working directory. Each MTP sample ships its own global.json, so the script runs from inside the
# sample folder for that switch to take effect without affecting the VSTest samples.
#
# MTP mode of `dotnet test` only exists in the .NET 10 SDK, so unlike the VSTest suites there is no
# net8.0/net9.0 variant of these tests.

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../test-dotnet.sh"
    export SAMPLES_PATH="${BATS_TEST_DIRNAME}/sample-projects"
}

# Runs the script from inside a sample project folder
run_script_in() {
    local project_folder=$1
    local test_project_pattern=$2

    pushd "$project_folder" > /dev/null

    # The 'run' command sets $status and $output for the test to use
    run "${SCRIPT_PATH}" "$test_project_pattern"

    popd > /dev/null
}

teardown() {
    # The script writes its results and tool manifest into the working directory, which is the sample folder here
    for sample in "${SAMPLES_PATH}"/mtp-*/; do
        rm -rf "${sample}covered-test-results" "${sample}.config" "${sample}dotnet-tools.json"
    done
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

@test "[net10.0] test-dotnet detects Microsoft.Testing.Platform from global.json and generates coverage and trx reports" {
    run_script_in "${SAMPLES_PATH}/mtp-basic" "**/*.UnitTests.csproj"

    [ "$status" -eq 0 ]

    # The runner was detected, not forced
    [[ "$output" == *"Running tests on: ./TestProject.UnitTests/TestProject.UnitTests.csproj (mtp)"* ]]

    # Check that the coverage report was generated
    [ -f "${SAMPLES_PATH}/mtp-basic/covered-test-results/reports/SummaryGithub.md" ]

    # Check that the trx report was generated where the action publishes it from (**/*.trx)
    [ -n "$(find "${SAMPLES_PATH}/mtp-basic/covered-test-results" -name '*.trx' -print -quit)" ]
}

@test "[net10.0] test-dotnet fails with package guidance when Microsoft.Testing.Platform extensions are missing" {
    run_script_in "${SAMPLES_PATH}/mtp-missing-extensions" "**/*.UnitTests.csproj"

    [ "$status" -ne 0 ]

    # The raw "Unknown option" output is turned into an actionable message
    [[ "$output" == *"Microsoft.Testing.Extensions.CodeCoverage"* ]]
    [[ "$output" == *"Microsoft.Testing.Extensions.TrxReport"* ]]

    # No coverage report should be generated
    [ ! -f "${SAMPLES_PATH}/mtp-missing-extensions/covered-test-results/reports/SummaryGithub.md" ]
}
