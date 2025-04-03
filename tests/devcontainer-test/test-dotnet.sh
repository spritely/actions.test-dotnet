#!/usr/bin/env bash

echo "test-dotnet.sh: $@" > /logs/test-dotnet.log
echo "NUGET_USER: ${NUGET_USER}" > /logs/test-dotnet.log
echo "NUGET_TOKEN: ${NUGET_TOKEN}" > /logs/test-dotnet.log
