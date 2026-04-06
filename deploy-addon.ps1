<#
Deploy UnitFramesLite addon files into a World of Warcraft AddOns folder.
Usage:
  powershell -ExecutionPolicy Bypass -File .\deploy-addon.ps1 -WoWPath "C:\Path\To\World of Warcraft" -GameType retail
  powershell -ExecutionPolicy Bypass -File .\deploy-addon.ps1 -WoWPath "C:\Path\To\World of Warcraft" -GameType classic
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$WoWPath,

    [Parameter(Mandatory=$false)]
    [ValidateSet("retail", "classic")]
    [string]$GameType = "retail"
)

$source = (Get-Location).Path

if (-not (Test-Path $WoWPath)) {
    Write-Error "WoW path not found: $WoWPath"
    exit 1
}

switch ($GameType) {
    "retail" { $target = Join-Path $WoWPath "_retail_\Interface\AddOns\UnitFramesLite" }
    "classic" { $target = Join-Path $WoWPath "_classic_\Interface\AddOns\UnitFramesLite" }
    default { Write-Error "Unknown GameType: $GameType"; exit 1 }
}

Write-Host "Deploying UnitFramesLite from:`n  $source`nto:`n  $target" -ForegroundColor Cyan

if (-not (Test-Path $source)) {
    Write-Error "Source path not found: $source"
    exit 1
}

# Ensure target folder exists
New-Item -ItemType Directory -Path $target -Force | Out-Null

$files = @(
    "UnitFramesLite.toc",
    "UnitFramesLite.lua",
    "UnitFramesLite.xml",
    "UnitFramesLite_Options.lua",
    "Elite.tga",
    "RareElite.tga"
)

foreach ($file in $files) {
    $src = Join-Path $source $file
    if (-not (Test-Path $src)) {
        Write-Error "Missing file: $src"
        exit 1
    }
    Copy-Item -Path $src -Destination $target -Force
    Write-Host "Copied $file" -ForegroundColor Green
}

# Copy Textures folder
$texSrc = Join-Path $source "Textures"
if (Test-Path $texSrc) {
    $texDst = Join-Path $target "Textures"
    New-Item -ItemType Directory -Path $texDst -Force | Out-Null
    Copy-Item -Path "$texSrc\*" -Destination $texDst -Recurse -Force
    Write-Host "Copied Textures\" -ForegroundColor Green
}

Write-Host "Deployment complete. Start WoW and /reload to test." -ForegroundColor Yellow
