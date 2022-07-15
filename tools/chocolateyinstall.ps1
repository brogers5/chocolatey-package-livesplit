$ErrorActionPreference = 'Stop'

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$archiveFileName = 'LiveSplit_1.8.20.zip'
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

$programsDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)
$shortcutFilePath = Join-Path -Path $programsDirectory -ChildPath "$softwareName.lnk"
$targetPath = Join-Path -Path $toolsDir -ChildPath 'LiveSplit.exe'
Install-ChocolateyShortcut -ShortcutFilePath $shortcutFilePath -TargetPath $targetPath -RunAsAdmin -ErrorAction SilentlyContinue

$pp = Get-PackageParameters
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
