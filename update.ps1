Import-Module au

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition)
. $currentPath\helpers.ps1

$legalPath = Join-Path -Path $currentPath -ChildPath 'legal'
$softwareRepo = 'LiveSplit/LiveSplit'

function global:au_GetLatest {
    $version = Get-LatestStableVersion

    return @{
        Url32           = Get-SoftwareUri
        Version         = $version #This may change if building a package fix version
        SoftwareVersion = $version
    }
}

function global:au_BeforeUpdate ($Package) {
    Get-RemoteFiles -Purge -NoSuffix -Algorithm sha256

    $templateFilePath = Join-Path -Path $legalPath -ChildPath 'VERIFICATION.txt.template'
    $verificationFilePath = Join-Path -Path $legalPath -ChildPath 'VERIFICATION.txt'
    Copy-Item -Path $templateFilePath  -Destination $verificationFilePath -Force

    Set-DescriptionFromReadme -Package $Package -ReadmePath ".\DESCRIPTION.md"
}

function global:au_AfterUpdate ($Package) {
    $licenseUri = "https://raw.githubusercontent.com/$($softwareRepo)/$($Latest.SoftwareVersion)/LICENSE"
    $licenseContents = Invoke-WebRequest -Uri $licenseUri -UseBasicParsing

    $licensePath = Join-Path -Path $legalPath -ChildPath 'LICENSE.txt'
    Set-Content -Path $licensePath -Value "From: $licenseUri`r`n`r`n$licenseContents"
}

function global:au_SearchReplace {
    @{
        "$($Latest.PackageName).nuspec" = @{
            "<packageSourceUrl>[^<]*</packageSourceUrl>" = "<packageSourceUrl>https://github.com/brogers5/chocolatey-package-$($Latest.PackageName)/tree/v$($Latest.Version)</packageSourceUrl>"
            "<licenseUrl>[^<]*</licenseUrl>"             = "<licenseUrl>https://github.com/$($softwareRepo)/blob/$($Latest.SoftwareVersion)/LICENSE</licenseUrl>"
            "<projectSourceUrl>[^<]*</projectSourceUrl>" = "<projectSourceUrl>https://github.com/$($softwareRepo)/tree/$($Latest.SoftwareVersion)</projectSourceUrl>"
            "<releaseNotes>[^<]*</releaseNotes>"         = "<releaseNotes>https://github.com/$($softwareRepo)/releases/tag/$($Latest.SoftwareVersion)</releaseNotes>"
            "<copyright>[^<]*</copyright>"               = "<copyright>Copyright (c) 2013-$(Get-Date -Format yyyy) Christopher Serr and Sergey Papushin</copyright>"
        }
        'legal\VERIFICATION.txt'        = @{
            '%checksumValue%'   = "$($Latest.Checksum32)"
            '%checksumType%'    = "$($Latest.ChecksumType32.ToUpper())"
            '%tagReleaseUrl%'   = "https://github.com/$($softwareRepo)/releases/tag/$($Latest.SoftwareVersion)"
            '%archiveUrl%'      = "$($Latest.Url32)"
            '%archiveFileName%' = "$($Latest.FileName32)"
        }
        'tools\chocolateyinstall.ps1'   = @{
            "(^[$]archiveFileName\s*=\s*)('.*')" = "`$1'$($Latest.FileName32)'"
        }
    }
}

Update-Package -ChecksumFor None -NoReadme
