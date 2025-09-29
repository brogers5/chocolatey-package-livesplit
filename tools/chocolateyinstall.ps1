$ErrorActionPreference = 'Stop'

$archiveFileName = 'LiveSplit_1.8.34.zip'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$archiveFilePath = Join-Path -Path $toolsDir -ChildPath $archiveFileName
$unzipLocation = Join-Path -Path (Get-ToolsLocation) -ChildPath $env:ChocolateyPackageName

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $unzipLocation
  fileFullPath  = $archiveFilePath
}

Get-ChocolateyUnzip @packageArgs

#Clean up ZIP archive post-install to prevent unnecessary disk bloat
Remove-Item $archiveFilePath -Force -ErrorAction SilentlyContinue

$softwareName = 'LiveSplit'
$binaryFileName = 'LiveSplit.exe'
$linkName = "$softwareName.lnk"
$targetPath = Join-Path -Path $unzipLocation -ChildPath $binaryFileName

$pp = Get-PackageParameters
if (!$pp.NoShim) {
  Install-BinFile -Name $softwareName -Path $targetPath -UseStart
}

if (!$pp.NoDesktopShortcut) {
  $desktopDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
  $shortcutFilePath = Join-Path -Path $desktopDirectory -ChildPath $linkName
  Install-ChocolateyShortcut -ShortcutFilePath $shortcutFilePath -TargetPath $targetPath -ErrorAction SilentlyContinue
}

if (!$pp.NoProgramsShortcut) {
  $programsDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)
  $shortcutFilePath = Join-Path -Path $programsDirectory -ChildPath $linkName
  Install-ChocolateyShortcut -ShortcutFilePath $shortcutFilePath -TargetPath $targetPath -ErrorAction SilentlyContinue
}

if ($pp.Start) {
  try {
    Start-Process -FilePath $targetPath -ErrorAction Continue
  }
  catch {
    Write-Warning "$softwareName failed to start, please try to manually start it instead."
  }
}
