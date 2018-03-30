function Install-Openssh {
   param ( $TempDir="$env:temp\opensshInstall" )
   if(!(Test-Path -Path $TempDir -PathType Container))
    {
       $null = New-Item -Type Directory -Path $TempDir -Force
    }
   $client = new-object System.Net.WebClient
   $client.DownloadFile("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v0.0.12.0/OpenSSH-Win64.zip", "$TempDir\OpenSSH-Win32.zip" )
   #Expand-Archive -Path $TempDir\OpenSSH-Win32.zip -DestinationPath $env:programfiles
   $Env:Path += ";$env:programfiles\OpenSSH-Win32"
   #[Environment]::SetEnvironmentVariable('PATH', $Env:Path, 'Machine')
}