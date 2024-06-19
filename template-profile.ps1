function CloneAndPullAndDotSourceScript($targetDir, $cloneUrl, $repoName) {
    if (-Not (Test-Path $targetDir -PathType Container))
    {
        New-Item -ItemType Directory -Force -Path $targetDir
        git -C $targetDir clone $cloneUrl | out-null
        return
    }

    $repoPath = Join-Path -Path $targetDir -ChildPath $repoName
    git -C $repoPath pull | out-null
    $customProfile = Join-Path -Path $repoPath -ChildPath 'Microsoft.PowerShell_profile.ps1'
    #Write-Host $customProfile
    $customProfile
}

$targetDir = 'C:\Admin\freaxnx01'
$repoName = 'powershell'
$cloneUrl = "https://github.com/freaxnx01/$repoName.git"
$customProfile = CloneAndPullAndDotSourceScript $targetDir $cloneUrl $repoName
#Write-Host $customProfile
. $customProfile

$targetDir = 'C:\Admin\anim-bossinfo-ch'
$repoName = 'PowerShell'
$cloneUrl = "https://github.com/anim-bossinfo-ch/$repoName.git"
$customProfile = CloneAndPullAndDotSourceScript $targetDir $cloneUrl $repoName
#Write-Host $customProfile
. $customProfile