#Collect Encrypted File
$encryptedpwd = Get-Content "C:\Scripts\enctxtfl.txt" | ConvertTo-SecureString
#Convert to pure plain text to call EXE
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedpwd))
