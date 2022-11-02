Import-Module PowerShellForGitHub

$installerFileNameRegex = 'LiveSplit_([\d\.]+)\.zip$'
$owner = 'LiveSplit'
$repository = 'LiveSplit'

function Get-LatestStableVersion
{
    $latestRelease = (Get-GitHubRelease -OwnerName $owner -RepositoryName $repository -Latest)[0]

    return [Version] $latestRelease.tag_name
}

function Get-SoftwareUri
{
    [CmdletBinding()]
    param(
        [Version] $Version
    )

    if ($null -eq $Version)
    {
        # Default to latest stable version
        $release = (Get-GitHubRelease -OwnerName $owner -RepositoryName $repository -Latest)[0]
    }
    else 
    {
        $release = Get-GitHubRelease -OwnerName $owner -RepositoryName $repository -Tag $Version.ToString()
    }

    $releaseAssets = Get-GitHubReleaseAsset -OwnerName $owner -RepositoryName $repository -Release $release.ID

    $windowsArchiveAsset = $null
    foreach ($asset in $releaseAssets)
    {
        if ($asset.name -match $installerFileNameRegex)
        {
            $windowsArchiveAsset = $asset
            break;
        }
        else {
            continue;
        }
    }

    if ($null -eq $windowsArchiveAsset)
    {
        throw "Cannot find published Windows archive asset!"
    }

    return $windowsArchiveAsset.browser_download_url
}