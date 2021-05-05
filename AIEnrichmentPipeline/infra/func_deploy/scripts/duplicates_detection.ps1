dotnet publish ../../../functions/enrichmentpipeline.Functions.DuplicatesDetection/EnrichmentPipleine.Functions.DuplicatesDetection.csproj -c Release -o ./build

Get-ChildItem -Path ./build | Compress-Archive -DestinationPath ../functionapp.zip -Force