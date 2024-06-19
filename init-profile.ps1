function CloneAndPullAndDotSourceScript($targetDir, $cloneUrl, $repoName) {
    if (-Not (Test-Path $targetDir -PathType Container))
    {
        New-Item -ItemType Directory -Force -Path $targetDir
        git -C $targetDir clone $cloneUrl
    }

    $repoPath = Join-Path -Path $targetDir -ChildPath $repoName
    git -C $repoPath pull | out-null
    . "$repoPath\Microsoft.PowerShell_profile.ps1"
}

$targetDir = 'C:\Admin\freaxnx01'
$repoName = 'powershell'
$cloneUrl = "https://github.com/freaxnx01/$repoName.git"
CloneAndPullAndDotSourceScript $targetDir $cloneUrl $repoName

$targetDir = 'C:\Admin\anim-bossinfo-ch'
$repoName = 'PowerShell'
$cloneUrl = "https://github.com/anim-bossinfo-ch/$repoName.git"
CloneAndPullAndDotSourceScript $targetDir $cloneUrl $repoName