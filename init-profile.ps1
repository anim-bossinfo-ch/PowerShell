if (-Not (Test-Path $profile))
{
	Invoke-WebRequest -Uri https://raw.githubusercontent.com/anim-bossinfo-ch/PowerShell/main/template-profile.ps1 -OutFile $profile
}
