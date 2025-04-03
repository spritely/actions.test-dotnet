#!/usr/bin/env bash

exitStatus=0

# To find new versions of dotnet-reportgenerator-globaltool
# See: https://www.nuget.org/packages/dotnet-reportgenerator-globaltool
dotnet tool install --create-manifest-if-needed dotnet-reportgenerator-globaltool --version 5.4.5

# Run tests and generate coverage report
find . -type f -iwholename "*$1" -exec dotnet test {} --configuration Release --collect:"XPlat Code Coverage" --collect:"Code Coverage" --logger:trx --results-directory "covered-test-results/" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=cobertura \;
exitStatus=$((status + $?))

dotnet reportgenerator -targetdir:./covered-test-results/reports/ -reports:./covered-test-results/**/coverage.cobertura.xml -verbosity:Info -reporttypes:"Badges;MarkdownSummary;MarkdownSummaryGitHub;HtmlInline_AzurePipelines_Dark"
exitStatus=$((status + $?))

exit $exitStatus
