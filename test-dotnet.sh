#!/usr/bin/env bash
set -euo pipefail

# reportgenerator releases: https://www.nuget.org/packages/dotnet-reportgenerator-globaltool
# renovate: datasource=nuget depName=dotnet-reportgenerator-globaltool
REPORTGENERATOR_VERSION="${REPORTGENERATOR_VERSION:-5.4.8}"

# Default threshold if not provided
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-90}

# Directory holding this script and the files shipped next to it (coverage.settings.xml)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Microsoft Code Coverage settings file (XML) used when tests run on Microsoft.Testing.Platform.
# Shipped next to this script and equivalent to the coverlet settings passed to the VSTest runner.
coverage_settings="$script_dir/coverage.settings.xml"

# To find new versions of dotnet-reportgenerator-globaltool
# See: https://www.nuget.org/packages/dotnet-reportgenerator-globaltool
dotnet tool install --create-manifest-if-needed dotnet-reportgenerator-globaltool --version $REPORTGENERATOR_VERSION --allow-downgrade

# True when the global.json governing this working directory switches `dotnet test` to
# Microsoft.Testing.Platform, i.e. it contains: "test": { "runner": "Microsoft.Testing.Platform" }
# The SDK resolves global.json by walking up from the current directory, so do the same.
global_json_uses_mtp() {
    local dir=$PWD
    while :; do
        if [ -f "$dir/global.json" ]; then
            if grep -Eq '"runner"[[:space:]]*:[[:space:]]*"Microsoft\.Testing\.Platform"' "$dir/global.json"; then
                return 0
            fi
            return 1
        fi
        if [ "$dir" = "/" ]; then
            return 1
        fi
        dir=$(dirname "$dir")
    done
}

# Prints "mtp" when `dotnet test` runs projects through Microsoft.Testing.Platform, otherwise "vstest".
# Detected the same way the SDK does: from the global.json governing the working directory.
detect_runner() {
    if global_json_uses_mtp; then
        echo "mtp"
    else
        echo "vstest"
    fi
}

# VSTest runner (.NET 8/9, and .NET 10 without the global.json switch):
# coverage and trx come from the coverlet and trx data collectors.
run_vstest() {
    local project=$1

    dotnet test "$project" --configuration Debug --collect:"XPlat Code Coverage" --collect:"Code Coverage" --logger:trx --results-directory "covered-test-results/" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=cobertura DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.ExcludeByAttribute=GeneratedCodeAttribute DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.SkipAutoProps=true 'DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.ExcludeByFile=**/*.pb.cs%2c**/*.grpc.cs'
}

# Microsoft.Testing.Platform runner (.NET 10 with "test": { "runner": "Microsoft.Testing.Platform" } in global.json):
# `dotnet test` forwards the options straight to the test application, so coverage and trx come from the
# Microsoft.Testing.Extensions.CodeCoverage and Microsoft.Testing.Extensions.TrxReport packages instead.
run_mtp() {
    local project=$1
    local name=${project##*/}
    name=${name%.*}

    # One results directory per project so coverage and trx files never collide
    local results_dir="covered-test-results/$name"
    local counter=1
    while [ -e "$results_dir" ]; do
        results_dir="covered-test-results/$name-$counter"
        counter=$((counter + 1))
    done

    # The test application is launched by dotnet test, so pass absolute paths to be independent of its working directory
    dotnet test --project "$project" --configuration Debug --results-directory "$PWD/$results_dir" --coverage --coverage-output-format cobertura --coverage-output "coverage.cobertura.xml" --coverage-settings "$coverage_settings" --report-trx --report-trx-filename "$name.trx"
    local mtp_status=$?

    if [ "$mtp_status" -ne 0 ]; then
        explain_missing_mtp_extensions "$project"
    fi

    return "$mtp_status"
}

# When a Microsoft.Testing.Platform run fails, asks the built test application which options it supports and,
# if --coverage or --report-trx are not among them, names the extension packages that provide them.
# Whether `dotnet test` echoes the application's "Unknown option" output depends on the SDK version, so the
# application itself is the only reliable source.
explain_missing_mtp_extensions() {
    local project=$1
    local target options
    local missing=()

    # The application was just built by dotnet test, so its output path is known to MSBuild
    target=$(dotnet msbuild "$project" -nologo -getProperty:TargetPath -property:Configuration=Debug 2>/dev/null) || return 0
    if [ ! -f "$target" ]; then
        return 0
    fi

    options=$(dotnet "$target" --help 2>&1 | grep -oE -- '--[a-z][a-z-]+' | sort -u) || true

    # Only trust the answer when it is an option list (it always contains --help itself)
    if ! grep -qx -- '--help' <<< "$options"; then
        return 0
    fi

    if ! grep -qx -- '--coverage' <<< "$options"; then
        missing+=("Microsoft.Testing.Extensions.CodeCoverage")
    fi
    if ! grep -qx -- '--report-trx' <<< "$options"; then
        missing+=("Microsoft.Testing.Extensions.TrxReport")
    fi

    if [ ${#missing[@]} -eq 0 ]; then
        return 0
    fi

    echo ""
    echo "❌ $project runs on Microsoft.Testing.Platform but does not support code coverage and/or trx reports."
    echo "   Add these package references to the test project, with versions built for the same Microsoft.Testing.Platform major as your test framework:"
    for package in "${missing[@]}"; do
        echo "     <PackageReference Include=\"$package\" Version=\"...\" />"
    done
    echo "   See the 'Test runners' section of the actions.test-dotnet README for the version matrix."
    echo ""
}

# Initialize exit status
exit_status=0

# Store matching project files in an array
readarray -t projects < <(find . -type f -iwholename "*$1")

if [ ${#projects[@]} -gt 0 ]; then

    runner=$(detect_runner)

    if [ "$runner" = "mtp" ] && [ ! -f "$coverage_settings" ]; then
        echo "❌ Coverage settings file not found: $coverage_settings"
        exit 1
    fi

    # Temporarily disable exit on error for this command
    set +e

    for project in "${projects[@]}"; do
        echo "Running tests on: $project ($runner)"

        if [ "$runner" = "mtp" ]; then
            run_mtp "$project"
        else
            run_vstest "$project"
        fi

        # Capture any errors
        exit_status=$((exit_status + $?))
    done

    # Re-enable exit on error
    set -e

    # Generate coverage report
    dotnet reportgenerator -targetdir:./covered-test-results/reports/ -reports:'./covered-test-results/**/*.cobertura.xml' -verbosity:Info -reporttypes:"MarkdownSummaryGitHub"

    # Replace title "# Summary" with "# Code Coverage Results"
    sed -i 's/# Summary/# Code Coverage Results/' ./covered-test-results/reports/SummaryGithub.md

    # Read code coverage
    # Line should be similar to this:
    # | **Line coverage:** | 92.6% (830 of 896) | -> 92.6% (830 of 896) -> 92.6%
    coverage=$(grep "\*\*Line coverage:\*\*" ./covered-test-results/reports/SummaryGithub.md | awk -F '|' '{print $3}' | awk '{print $1}')

    # Remove the '%' sign for comparison
    coverage=${coverage%\%}

    # Ensure exactly 2 decimal places then remove the decimal point
    coverage_int=$(printf "%.2f" "${coverage:-0}" | tr -d '.')
    threshold_int=$(printf "%.2f" "$COVERAGE_THRESHOLD" | tr -d '.')

    if (( coverage_int > 0 )); then
        echo "Line coverage: $coverage%"

        # Add the threshold information to the end of the report
        echo "" >> ./covered-test-results/reports/SummaryGithub.md
        echo "## Coverage Threshold" >> ./covered-test-results/reports/SummaryGithub.md
        echo "" >> ./covered-test-results/reports/SummaryGithub.md
        echo "Required minimum: $COVERAGE_THRESHOLD%" >> ./covered-test-results/reports/SummaryGithub.md
        echo "Actual coverage: $coverage%" >> ./covered-test-results/reports/SummaryGithub.md
        echo "" >> ./covered-test-results/reports/SummaryGithub.md

        # Check if coverage meets threshold
        if (( coverage_int < threshold_int )); then
            echo "❌ Code coverage must be at least $COVERAGE_THRESHOLD%, but was $coverage%"
            echo "❌ **Code coverage must be at least $COVERAGE_THRESHOLD%, but was $coverage%**" >> ./covered-test-results/reports/SummaryGithub.md
            exit_status=1
        else
            echo "✅ Coverage threshold met ($coverage% >= $COVERAGE_THRESHOLD%)"
            echo "✅ **Coverage threshold met ($coverage% >= $COVERAGE_THRESHOLD%)**" >> ./covered-test-results/reports/SummaryGithub.md
        fi
    fi

fi

# Exit with the status from the tests
exit $exit_status
