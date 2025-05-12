# !/bin/sh
dotnet nuget update source --password $GITHUB_PAT --username stephanpoelwijk --store-password-in-clear-text github
