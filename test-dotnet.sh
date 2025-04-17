#!/usr/bin/env bash
set -euo pipefail

# Default threshold if not provided
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-90}

# To find new versions of dotnet-reportgenerator-globaltool
# See: https://www.nuget.org/packages/dotnet-reportgenerator-globaltool
dotnet tool install --create-manifest-if-needed dotnet-reportgenerator-globaltool --version 5.4.5

# Initialize exit status
exit_status=0

# Store matching project files in an array
readarray -t projects < <(find . -type f -iwholename "*$1")

if [ ${#projects[@]} -gt 0 ]; then

    # Temporarily disable exit on error for this command
    set +e

    for project in "${projects[@]}"; do
        echo "Running tests on: $project"
        dotnet test "$project" --configuration Debug --collect:"XPlat Code Coverage" --collect:"Code Coverage" --logger:trx --results-directory "covered-test-results/" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=cobertura

        # Capture any errors
        exit_status=$((exit_status + $?))
    done

    # Re-enable exit on error
    set -e

    # Generate coverage report
    dotnet reportgenerator -targetdir:./covered-test-results/reports/ -reports:./covered-test-results/**/coverage.cobertura.xml -verbosity:Info -reporttypes:"MarkdownSummaryGitHub"

    # Replace title "# Summary" with "# Code Coverage Results"
    sed -i 's/# Summary/# Code Coverage Results/' ./covered-test-results/reports/SummaryGithub.md

    # Read code coverage
    # Line should be similar to this:
    # | **Line coverage:** | 92.6% (830 of 896) | -> 92.6% (830 of 896) -> 92.6%
    coverage=$(grep "\*\*Line coverage:\*\*" ./covered-test-results/reports/SummaryGithub.md | awk -F '|' '{print $3}' | awk '{print $1}')

    # Remove the '%' sign for comparison
    coverage=${coverage%\%}

    # Ensure exactly 2 decimal places then remove the decimal point
    coverage_int=$(printf "%.2f" "$coverage" | tr -d '.')
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
