$ErrorActionPreference = 'Stop'

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$archiveFileName = 'LiveSplit_1.8.25.zip'
$archiveFilePath = Join-Path -Path $toolsDir -ChildPath $archiveFileName

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileFullPath  = $archiveFilePath
}

Get-ChocolateyUnzip @packageArgs

#Clean up ZIP archive post-install to prevent unnecessary disk bloat
Remove-Item $archiveFilePath -Force -ErrorAction SilentlyContinue

$softwareName = 'LiveSplit'
$binaryFileName = 'LiveSplit.exe'
$linkName = "$softwareName.lnk"
$targetPath = Join-Path -Path $toolsDir -ChildPath $binaryFileName

$pp = Get-PackageParameters
if ($pp.NoShim)
{
  #Create shim ignore file
  $ignoreFilePath = Join-Path -Path $toolsDir -ChildPath "$binaryFileName.ignore"
  Set-Content -Path $ignoreFilePath -Value $null -ErrorAction SilentlyContinue
}
else
{
  #Create GUI shim
  $guiShimPath = Join-Path -Path $toolsDir -ChildPath "$binaryFileName.gui"
  Set-Content -Path $guiShimPath -Value $null -ErrorAction SilentlyContinue
}

if (!$pp.NoDesktopShortcut)
{
  $desktopDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
  $shortcutFilePath = Join-Path -Path $desktopDirectory -ChildPath $linkName
  Install-ChocolateyShortcut -ShortcutFilePath $shortcutFilePath -TargetPath $targetPath -RunAsAdmin -ErrorAction SilentlyContinue
}

if (!$pp.NoProgramsShortcut)
{
  $programsDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)
  $shortcutFilePath = Join-Path -Path $programsDirectory -ChildPath $linkName
  Install-ChocolateyShortcut -ShortcutFilePath $shortcutFilePath -TargetPath $targetPath -RunAsAdmin -ErrorAction SilentlyContinue
}

if ($pp.Start)
{
  try
  {
    Start-Process -FilePath $targetPath -ErrorAction Continue
  }
  catch
  {
    Write-Warning "$softwareName failed to start, please try to manually start it instead."
  }
}
