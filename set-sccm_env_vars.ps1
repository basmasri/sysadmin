#-----------------------------------------------//------------------------------------------------#

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
#Add-Type -AssemblyName System.Drawing
#Add-Type -AssemblyName System.Windows.Forms

$log = 'x:\Windows\Temp\CLILog.log'

#-------------------------------------------------------------------------------------------------#

# Add controls to form and then display on screen
function Load-DTForm
{
    $Form1.Controls.Add($TBDeviceType)
    $Form1.Controls.Add($GBDeviceType)
    $Form1.Controls.Add($DTButtonOK)
    $Form1.Add_Shown({$Form1.Activate()})
    [void] $Form1.ShowDialog()
}

#-------------------------------//---------------------------------#

# Checks the device type entry that the form gets is valid
function Get-DeviceType
{
    $validSelection = $false
    $DTErrorProvider.Clear()
    if ($TBDeviceType.Text.Length -eq 0)
    { $DTErrorProvider.SetError($GBDeviceType, "Enter number of device type"); $TBDeviceType.Focus() }
    else {
        switch ($TBDeviceType.Text)
        {
            "1" { $validSelection = $true }
            "2" { $validSelection = $true }
            "3" { $validSelection = $true }
            "4" { $validSelection = $true }
            "5" { $validSelection = $true }
            "6" { $validSelection = $true }
            "7" { $validSelection = $true }
            "8" { $validSelection = $true }
            default { $DTErrorProvider.SetError($GBDeviceType, "Device type selection is not valid"); $TBDeviceType.SelectAll(); $TBDeviceType.Focus() }
        } 

        if ($validSelection)
        {
            $Form1.Close()
        }
    }
}

#-------------------------------//---------------------------------#

# Build all form objects and add actions


$DTMessage = "Select the device type:`n`n• 1) Student`n• 2) Staff`n• 3) Library Loans`n• 4) Library Workstations`n• 5) Music Workstations`n• 6) General Office`n• 7) CRT`n• 8) Public"

$Global:DTErrorProvider = New-Object System.Windows.Forms.ErrorProvider
$Form1 = New-Object System.Windows.Forms.Form
$Form1.Size = New-Object System.Drawing.Size(350,500)
$Form1.MinimumSize = New-Object System.Drawing.Size(350,500)
$Form1.MaximumSize = New-Object System.Drawing.Size(350,500)
$Form1.StartPosition = "Manual"
$Form1.SizeGripStyle = "Hide"
$Form1.Text = "Device Type"
$Form1.ControlBox = $false
$Form1.TopMost = $true

$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(20,320)
$label1.Size = New-Object System.Drawing.Size(160,30)
$label1.Text = 'Enter Selection 1-8:'
$form1.Controls.Add($label1)

$TBDeviceType = New-Object System.Windows.Forms.TextBox
$TBDeviceType.Location = New-Object System.Drawing.Point(15,370)
$TBDeviceType.Size = New-Object System.Drawing.Size(100,20)
$TBDeviceType.TabIndex = "2"
$TBDeviceType.MaxLength = 2
$TBDeviceType.Text = "1"

$GBDeviceType = New-Object System.Windows.Forms.GroupBox
$GBDeviceType.Location = New-Object System.Drawing.Size(20,10)
$GBDeviceType.Size = New-Object System.Drawing.Size(295,295)
$GBDeviceType.Text = "$DTMessage"

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(200,370)
$cancelButton.Size = New-Object System.Drawing.Size(60,25)
$cancelButton.Text = 'Close'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form1.CancelButton = $cancelButton
$form1.Controls.Add($cancelButton)

$DTButtonOK = New-Object System.Windows.Forms.Button
$DTButtonOK.Location = New-Object System.Drawing.Size(160,370)
$DTButtonOK.Size = New-Object System.Drawing.Size(40,25)
$DTButtonOK.Text = "OK"
$DTButtonOK.TabIndex = "2"
$DTButtonOK.Add_Click({ Get-DeviceType })

$Form1.KeyPreview = $True
$Form1.Add_KeyDown({if ($_.KeyCode -eq "Enter"){ Get-DeviceType }})
# Set actions to when form is shown
$Form1.Add_Shown({ $TBDeviceType.Focus() })
Load-DTForm


#-------------------------------//---------------------------------#

$Global:intDeviceType = $TBDeviceType.Text -as [int]

$env = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Set TS environment variable based on device type chosen
switch ($intDeviceType)
{
    1 { $env.Value('DeviceType') = 'Students' }
    2 { $env.Value('DeviceType') = 'Staff' }
    3 { $env.Value('DeviceType') = 'Library Loans' }
    4 { $env.Value('DeviceType') = 'Library Workstations' }
    5 { $env.Value('DeviceType') = 'Music Workstations' }
    6 { $env.Value('DeviceType') = 'General Office' }
    7 { $env.Value('DeviceType') = 'CRT' }
    8 { $env.Value('DeviceType') = 'Public' }
}

# Output to log file with variable value
$intDeviceType | Out-File -FilePath $Log -Append -NoClobber

#-------------------------------//---------------------------------#

# WMI queries to get information on device
$tempCS = Get-WmiObject Win32_computersystem
$tempSE = Get-WmiObject Win32_SystemEnclosure
$tempBIOS = Get-WmiObject Win32_BIOS

# Populate variables for checking model and setting device name
$strMfg = $tempCS.Manufacturer.TrimEnd()
$strModel = $tempCS.Model.TrimEnd()
$strCSName = $tempCS.Name.TrimEnd()
$strAssetTag = $tempSE.SMBIOSAssetTag.TrimEnd()
$strSerialNumber = $tempBIOS.SerialNumber.TrimEnd()

# Output to log file with variable values
$strMfg | Out-File -FilePath $Log -Append -NoClobber
$strModel | Out-File -FilePath $Log -Append -NoClobber
$strCSName | Out-File -FilePath $Log -Append -NoClobber
$strAssetTag | Out-File -FilePath $Log -Append -NoClobber
$strSerialNumber | Out-File -FilePath $Log -Append -NoClobber

# Set variable for device name based on serial or asset tag
if ("$strAssetTag" -match "No Asset Information" -Or "$strAssetTag" -match "No Asset Tag")
{ $strNewDeviceName = $strSerialNumber.ToUpper() }
elseif (!($strAssetTag))
{ $strNewDeviceName = $strSerialNumber.ToUpper() }
elseif ($strAssetTag)
{ $strNewDeviceName = $strAssetTag.ToUpper() }

#-------------------------------//---------------------------------#

# Checks device name exists and is a valid length
if (!($strNewDeviceName) -Or
    ($intDeviceType -eq 2 -And $strNewDeviceName.Length -gt 15) -Or
    (($intDeviceType -eq 1 -Or $intDeviceType -eq 8) -And $strNewDeviceName.Length -gt 12) -Or
    ($strNewDeviceName -notmatch "^[a-zA-Z0-9-]+$"))
{
    #-------------------------------//---------------------------------#

    # Add controls to form and then display on screen
    function Load-SNForm
    {
        $Form2.Controls.Add($TBSerialNumber)
        $Form2.Controls.Add($GBSerialNumber)
        $Form2.Controls.Add($DTButtonOK)
        $Form2.Add_Shown({$Form2.Activate()})
        [void] $Form2.ShowDialog()
    }

    #-------------------------------//---------------------------------#

    # Checks the serial number entry that the form gets is valid
    function Get-SerialNumber
    {
        $validSelection = $false
        $SNErrorProvider.Clear()
        if ($TBSerialNumber.Text.Length -eq 0)
        { $SNErrorProvider.SetError($GBSerialNumber, "Serial number or device name cannot be blank"); $TBSerialNumber.Focus() }
        elseif ($intDeviceType -eq 2 -And $TBSerialNumber.Text.Length -gt 15)
        { $SNErrorProvider.SetError($GBSerialNumber, "Length cannot exceed 15 characters for Staff"); $TBSerialNumber.SelectAll(); $TBSerialNumber.Focus() }
        elseif (($intDeviceType -eq 1 -Or $intDeviceType -eq 8) -And $TBSerialNumber.Text.Length -gt 12)
        { $SNErrorProvider.SetError($GBSerialNumber, "Length cannot exceed 12 characters for Student or Public"); $TBSerialNumber.SelectAll(); $TBSerialNumber.Focus() }
        else {
            if ($TBSerialNumber.Text -notmatch "^[a-zA-Z0-9-]+$")
            { $SNErrorProvider.SetError($GBSerialNumber, "Entry can only contain letters, hyphens and numbers"); $TBSerialNumber.SelectAll(); $TBSerialNumber.Focus() }

            else { $Form2.Close(); $validSelection = $true }
        }

        if (!($validSelection)) { $GBSerialNumber.Text = "$SNMessage" }
    }

    #-------------------------------//---------------------------------#

    # Build all form objects and add actions

    $SNInvalid = "Serial number invalid - "
    $Global:SNMessage = "Enter serial number or device name"

    $Global:SNErrorProvider = New-Object System.Windows.Forms.ErrorProvider
    $Form2 = New-Object System.Windows.Forms.Form
    $Form2.Size = New-Object System.Drawing.Size(305,175)
    $Form2.MinimumSize = New-Object System.Drawing.Size(305,175)
    $Form2.MaximumSize = New-Object System.Drawing.Size(305,175)
    $Form2.StartPosition = "Manual"
    $Form2.SizeGripStyle = "Hide"
    $Form2.Text = "Serial Number"
    $Form2.ControlBox = $false
    $Form2.TopMost = $true

    $TBSerialNumber = New-Object System.Windows.Forms.TextBox
    $TBSerialNumber.Location = New-Object System.Drawing.Size(30,55)
    $TBSerialNumber.Size = New-Object System.Drawing.Size(220,50)
    $TBSerialNumber.TabIndex = "1"

    $GBSerialNumber = New-Object System.Windows.Forms.GroupBox
    $GBSerialNumber.Location = New-Object System.Drawing.Size(20,10)
    $GBSerialNumber.Size = New-Object System.Drawing.Size(245,75)
    $GBSerialNumber.Text = "$SNInvalid" + "$SNMessage"

    $DTButtonOK = New-Object System.Windows.Forms.Button
    $DTButtonOK.Location = New-Object System.Drawing.Size(215,95)
    $DTButtonOK.Size = New-Object System.Drawing.Size(50,20)
    $DTButtonOK.Text = "OK"
    $DTButtonOK.TabIndex = "2"
    $DTButtonOK.Add_Click({Get-SerialNumber})

    $Form2.KeyPreview = $True
    $Form2.Add_KeyDown({if ($_.KeyCode -eq "Enter"){Get-SerialNumber}})
    # Set actions to when form is shown
    $Form2.Add_Shown({
        if ($strNewDeviceName)
        {
            $TBSerialNumber.Text = $strNewDeviceName
            $TBSerialNumber.SelectAll()
        }
        $TBSerialNumber.Focus()
    })
    Load-SNForm

    $strNewDeviceName = $TBSerialNumber.Text

    #-------------------------------//---------------------------------#
}

# Output to log file with variable value
$strNewDeviceName | Out-File -FilePath $Log -Append -NoClobber

#-------------------------------//---------------------------------#

# Check which model type is detected and set TS environment variable
switch -Wildcard ($strModel.ToUpper())

{
    "Latitude 3380"{
                $env.Value('OSDModelType') = 'Latitude3380'
                             if (!($intDeviceType -eq 3))
                                       { $Year = 'CRT' }
                              elseif (!($intDeviceType -eq 13))
                                       { $Year = 'LIB' }
                    }

                
    "20M8*" {
                $env.Value('OSDModelType') = 'YogaL380'
                $Year = '2019'
                #is device student or public
                if ($intDeviceType -eq 1)  { $strOU = "OU PATH" }
                }        
                
    "20NU*" {
                $env.Value('OSDModelType') = 'YogaL390'
                $Year = '2020'
                #is device student or public
                if ($intDeviceType -eq 1) { $strOU = "OU PATH" }
            }

     "20R*" {
                $env.Value('OSDModelType') = 'YogaL13'
                $Year = '2021'
                #is device student or public
                if ($intDeviceType -eq 1)  { $strOU = "OU PATH" }
            }

     "20V*" {
                $env.Value('OSDModelType') = 'YogaL13Gen2'
                $Year = '2021'
                #is device student or public
                if ($intDeviceType -eq 1)  { $strOU = "OU PATH" }
            }

      "HP EliteBook x360 830 G8 Notebook PC" {
                $env.Value('OSDModelType') = 'HPEliteBookX360'
                $Year = '2022'
                #is device student or public
                if ($intDeviceType -eq 1)  { $strOU = "OU PATH" }
            }


    default {
                $env.Value('OSDModelType') = 'Unknown'
                #is device student or public
                if ($intDeviceType -eq 1 -Or $intDeviceType -eq 8) { $strOU = 'OU PATH' }
            }
}

# Set TS environment variable with device OU
switch ($intDeviceType)


{
            1 { $env.Value('DeviceOU') = $strOU }
            2 { $env.Value('DeviceOU') = 'OU PATH' }
            3 { $env.Value('DeviceOU') = 'OU PATH' }
            4 { $env.Value('DeviceOU') = 'OU PATH' }
            5 { $env.Value('DeviceOU') = 'OU PATH' }
            6 { $env.Value('DeviceOU') = 'OU PATH' }
            7 { $env.Value('DeviceOU') = 'OU PATH' }
            8 { $env.Value('DeviceOU') = 'OU PATH' }
}



# Set TS environment variable with computer name

if (!($strOU))
{ $env.Value('OSDComputerName') = $strNewDeviceName }
else {
    if ($strNewDeviceName.Length -le 10)
        { $env.Value('OSDComputerName') = $Year + '-' + $strNewDeviceName }
    elseif ($strNewDeviceName.Length -le 12)
        { $env.Value('OSDComputerName') = $Year.Substring($Year.Length -2) + '-' + $strNewDeviceName }
          }

