param(
	[string]$RojoPath = "",
	[string]$LuauCompilerPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not $RojoPath) {
	$RojoPath = Join-Path $repoRoot "build\rojo\rojo.exe"
}
if (-not $LuauCompilerPath) {
	$LuauCompilerPath = Join-Path $repoRoot "build\luau\luau-compile.exe"
}
if (-not (Test-Path -LiteralPath $RojoPath)) {
	throw "Rojo was not found at $RojoPath. Install Rojo 7.7.1 or pass -RojoPath."
}
if (-not (Test-Path -LiteralPath $LuauCompilerPath)) {
	throw "Luau compiler was not found at $LuauCompilerPath. Install Luau 0.746 or pass -LuauCompilerPath."
}

$sourceRoot = Join-Path $PSScriptRoot "..\src"
$files = Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter "*.lua"
if ($files.Count -eq 0) {
	throw "No Luau files found in $sourceRoot."
}
foreach ($file in $files) {
	& $LuauCompilerPath $file.FullName *> $null
	if ($LASTEXITCODE -ne 0) {
		throw "Luau syntax validation failed: $($file.FullName)"
	}
	Write-Host "Luau OK: $($file.Name)"
}

$project = Join-Path $PSScriptRoot "..\default.project.json"
$output = Join-Path $PSScriptRoot "..\LINHA11_Roblox.rbxlx"
& $RojoPath build $project --output $output
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $output)) {
	throw "Rojo failed to build $output."
}
$size = (Get-Item -LiteralPath $output).Length
Write-Host "Place generated: $output ($size bytes)"
