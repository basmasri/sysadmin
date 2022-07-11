# Variables
$LogPath = 
$ExportedCSVPath =

# Create a log file

Start-Transcript -Path "$LogPath"
Write-Host

# Grab device name
$device = $(Get-WmiObject Win32_Computersystem).name

# Grab user profile
Get-WmiObject -Class Win32_NetworkLoginProfile -ComputerName $device |

# Sort WMIObject query to LastLogon
Sort-Object -Property LastLogon -Descending | 
Select-Object -Property * -First 1 | 
Where-Object {$_.LastLogon -match "(\d{14})"} | 

# Query and output Device, User and Last Logon timestamp, exporting data to CSV file
Foreach-Object { New-Object PSObject -Property @{Username=$_.Name;Computer=$device;LastLogon=[datetime]::ParseExact($matches[0], "yyyyMMddHHmmss", $null)}} | 
Export-Csv "$ExportedCSVPath" -Append

Stop-Transcript

exit
