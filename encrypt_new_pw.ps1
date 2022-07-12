$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content C:\Scripts\enctxtfl.txt
