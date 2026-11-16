[CmdletBinding()]
param(
  [string]$AssemblyInfoPath = "Properties\AssemblyInfo.cs",
  [string]$InstallerPath = "installer\SWAutoAttributes.iss",
  [string]$Version = $env:VERSION
)

function Replace-Required {
  param(
    [Parameter(Mandatory = $true)][string]$Content,
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][string]$Replacement,
    [Parameter(Mandatory = $true)][string]$Name
  )

  if ($Content -notmatch $Pattern) {
    throw "Cannot find $Name."
  }

  [regex]::Replace($Content, $Pattern, $Replacement, 1)
}

function Write-GitHubOutput {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Value
  )

  if ($env:GITHUB_OUTPUT) {
    "$Name=$Value" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
  }
}

if ($Version -notmatch '^([2-9][0-9]{3})\.([1-9]|1[0-2])\.([1-9][0-9]*)$') {
  throw "Version must be year.month.sequence."
}
$year = [int]$Matches[1]
$month = [int]$Matches[2]
$sequence = [uint32]$Matches[3]
$version = $Version
$assemblyVersion = "{0}.{1}.{2}.{3}" -f $year, $month, ($sequence -shr 16), ($sequence -band 65535)

$assemblyInfo = Get-Content $AssemblyInfoPath -Raw
$assemblyInfo = Replace-Required $assemblyInfo 'AssemblyVersion\("[^"]*"\)' "AssemblyVersion(`"$assemblyVersion`")" "AssemblyVersion"
$assemblyInfo = Replace-Required $assemblyInfo 'AssemblyFileVersion\("[^"]*"\)' "AssemblyFileVersion(`"$assemblyVersion`")" "AssemblyFileVersion"
$assemblyInfo = Replace-Required $assemblyInfo 'AssemblyInformationalVersion\("[^"]*"\)' "AssemblyInformationalVersion(`"$version`")" "AssemblyInformationalVersion"
Set-Content -Path $AssemblyInfoPath -Value $assemblyInfo -NoNewline

$installer = Get-Content $InstallerPath -Raw
$installer = Replace-Required $installer '#define AppVersion "[^"]*"' "#define AppVersion `"$version`"" "AppVersion"
$installer = Replace-Required $installer '#define AppFileVersion "[^"]*"' "#define AppFileVersion `"$assemblyVersion`"" "AppFileVersion"
Set-Content -Path $InstallerPath -Value $installer -NoNewline

Write-GitHubOutput "version" $version
Write-GitHubOutput "tag" $version
Write-GitHubOutput "release_name" $version

Write-Host "Build version: $version"
Write-Host "Assembly file version: $assemblyVersion"
