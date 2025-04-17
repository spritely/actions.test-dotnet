#!/usr/bin/env bash
set -euo pipefail

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
fi

# Exit with the status from the tests
exit $exit_status
