[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Write-Output ('Release build started ' + (Get-Date -Format o))
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
Set-Location -LiteralPath $root
$projects = @(Get-ChildItem -LiteralPath (Join-Path $root 'src') -Filter '*.csproj' -File -Recurse)
if ($projects.Count -ne 1) { throw 'Expected exactly one standalone application project.' }
$project = $projects[0]
[xml]$definition = Get-Content -LiteralPath $project.FullName -Raw
$version = $definition.SelectSingleNode('//Version').InnerText
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Expected a stable three-part application version.' }
if ($definition.SelectNodes('//ProjectReference').Count -ne 0) { throw 'The standalone app must consume public NuGet packages.' }
$app = $project.BaseName
$release = Join-Path $root "artifacts/release/$version"
$destination = Join-Path $release $app
$archive = Join-Path $release "$app.$version.win-x64.zip"
if (Test-Path -LiteralPath $release) { throw 'Release output already exists; use a fresh checkout or preserve and move the prior output explicitly.' }
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$cache = Join-Path $root 'artifacts/nuget-cache'
$build = Join-Path $root 'artifacts/release-build'

& dotnet publish $project.FullName -c Release -r win-x64 --self-contained false --artifacts-path $build -o $destination '-p:Platform=x64' '-p:RestoreLockedMode=true' '-p:UseSharedCompilation=false' '-p:PublishSingleFile=false' '-p:PublishTrimmed=false' "-p:RestorePackagesPath=$cache" '-m:1' '-warnaserror'
if ($LASTEXITCODE -ne 0) { throw 'Application publication failed.' }

$runtime = Get-Content -LiteralPath (Join-Path $destination "$app.runtimeconfig.json") -Raw | ConvertFrom-Json
if ($runtime.runtimeOptions.tfm -ne 'net10.0' -or $runtime.runtimeOptions.includedFrameworks -or
    @($runtime.runtimeOptions.frameworks | Where-Object { $_.name -eq 'Microsoft.WindowsDesktop.App' -and $_.version -like '10.*' }).Count -ne 1) {
    throw 'Expected a framework-dependent .NET 10 Windows Desktop application.'
}
foreach ($forbidden in @('coreclr.dll','hostfxr.dll','hostpolicy.dll','System.Private.CoreLib.dll','createdump.exe')) {
    if (Get-ChildItem -LiteralPath $destination -File -Recurse | Where-Object Name -eq $forbidden) { throw "Bundled runtime file detected: $forbidden" }
}
foreach ($required in @("$app.exe", "$app.dll", 'AbraxasDB.dll', 'InhetoSerializer.dll')) {
    if (-not (Test-Path -LiteralPath (Join-Path $destination $required))) { throw "Missing published application dependency: $required" }
}
Copy-Item -LiteralPath 'README.md','LICENSE','THIRD-PARTY-NOTICES.md','CHANGELOG.md' -Destination $destination
Copy-Item -LiteralPath 'licenses' -Destination $destination -Recurse
foreach ($metadata in Get-ChildItem -LiteralPath $cache -Filter '*.nuspec' -Recurse -File) {
    [xml]$package = Get-Content -LiteralPath $metadata.FullName -Raw
    $notices = Join-Path $destination "licenses/packages/$($package.package.metadata.id)/$($package.package.metadata.version)"
    New-Item -ItemType Directory -Path $notices -Force | Out-Null
    Copy-Item -LiteralPath $metadata.FullName -Destination $notices
    foreach ($notice in Get-ChildItem -LiteralPath $metadata.DirectoryName -File -Recurse | Where-Object { $_.Name -match '(?i)license|notice' }) {
        $target = Join-Path $notices ([IO.Path]::GetRelativePath($metadata.DirectoryName,$notice.FullName))
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $notice.FullName -Destination $target
    }
}
if ($app -eq 'AbraxasShowcase') {
    $examples = Join-Path $root 'artifacts/exported-examples'
    & dotnet (Join-Path $destination "$app.dll") --export-examples --output $examples
    if ($LASTEXITCODE -ne 0 -or @(Get-ChildItem -LiteralPath $examples -Filter '*.cs' -File -Recurse).Count -ne 82) {
        throw 'The published Showcase did not export all 82 example programs.'
    }
}
Compress-Archive -Path (Join-Path $destination '*') -DestinationPath $archive
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
"$hash  $([IO.Path]::GetFileName($archive))" | Set-Content -LiteralPath (Join-Path $release 'SHA256SUMS.txt') -Encoding utf8
@"
$app $version

Download the Windows x64 ZIP, extract all files, and run $app.exe.

Requires the .NET 10 Windows Desktop Runtime (x64):
https://dotnet.microsoft.com/en-us/download/dotnet/10.0

Also requires Microsoft Edge WebView2 Evergreen Runtime:
https://developer.microsoft.com/en-us/microsoft-edge/webview2/

This smaller framework-dependent ZIP does not bundle .NET or install either prerequisite.
Application data lives outside the extracted app by default. See README.md for --data and data-directory guidance.
AbraxasDB and its component libraries remain on .NET 8; this app consumes AbraxasDB 1.0.1 from NuGet.

SHA-256: $hash
"@ | Set-Content -LiteralPath (Join-Path $release 'RELEASE_NOTES.md') -Encoding utf8
Write-Output ("Release asset: $archive")
Write-Output ('Release build finished ' + (Get-Date -Format o))
