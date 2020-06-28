New-Item -ItemType Directory -Path C:\Patches
$url = "https://eafdstorage.blob.core.windows.net/agent/Agent.zip"


# Install the Exe
if (!(Test-Path C:\Patches\TLSSettings.ps1)) {
    "$(Get-Date) Start Download..." | Out-File "C:\Patches\dsc-log.txt" -Append
    Start-BitsTransfer -Source $url -Destination "C:\Patches\MonitorAgent.zip"
    "$(Get-Date) Start Download Complete" | Out-File "C:\Patches\dsc-log.txt" -Append
    Expand-Archive -LiteralPath C:\Patches\MonitorAgent.Zip -DestinationPath C:\Patches -Force
}
                
$TLSScript = "C:\patches\TLSSettings.ps1"
&$TLSScript -EnableOlderTlsVersions $True -RebootIfRequired $false

if (!(Test-Path C:\Patches\BackupUdpPortsLeakBinaries)) {
    New-Item -ItemType Directory -Path C:\Patches\BackupUdpPortsLeakBinaries
}

if (Test-Path C:\Patches\hostnetsvc.dll) {
    copy C:\windows\system32\hostnetsvc.dll C:\Patches\BackupUdpPortsLeakBinaries\hostnetsvc.dll
    C:\Patches\sfpcopy.exe C:\Patches\hostnetsvc.dll C:\windows\system32\hostnetsvc.dll
    "$(Get-Date) Copied hostnetsvc.dll..." | Out-File "C:\Patches\dsc-log.txt" -Append
}

if (Test-Path C:\Patches\vfpctrl.exe) {
    copy C:\windows\system32\vfpctrl.exe C:\Patches\BackupUdpPortsLeakBinaries\vfpctrl.exe
    C:\Patches\sfpcopy.exe C:\Patches\vfpctrl.exe C:\windows\system32\vfpctrl.exe
    "$(Get-Date) Copied vfpctrl.exe..." | Out-File "C:\Patches\dsc-log.txt" -Append
}

if (Test-Path C:\Patches\vfpapi.dll) {
    copy C:\windows\system32\vfpapi.dll C:\Patches\BackupUdpPortsLeakBinaries\vfpapi.dll
    C:\Patches\sfpcopy.exe C:\Patches\vfpapi.dll C:\windows\system32\vfpapi.dll
    "$(Get-Date) Copied vfpapi.dll..." | Out-File "C:\Patches\dsc-log.txt" -Append
}

if (Test-Path C:\Patches\vfpext.sys) {
    copy C:\windows\system32\drivers\vfpext.sys C:\Patches\BackupUdpPortsLeakBinaries\vfpext.sys
    C:\Patches\sfpcopy.exe C:\Patches\vfpext.sys C:\windows\system32\drivers\vfpext.sys
    "$(Get-Date) Copied vfpext.sys..." | Out-File "C:\Patches\dsc-log.txt" -Append
}

# Set DNSMaximumTTL to 60 seconds
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hns\State" /v DNSMaximumTTL /t REG_DWORD /d 60 /f
"$(Get-Date) Set DNSMaximumTTL Reg Key to 60 seconds..." | Out-File "C:\Patches\dsc-log.txt" -Append

if(!(Test-Path C:\MonitorAgent\data)) {
	New-Item -ItemType Directory -Path C:\MonitorAgent\data	
}

$fileIsComplete = $false
do {
    try {
        "$(Get-Date) Start Download..." | Out-File "C:\MonitorAgent\dsc-log.txt" -Append
        Start-BitsTransfer -Source $url -Destination "C:\MonitorAgent\MonitorAgent.zip"
        "$(Get-Date) Start Download Complete" | Out-File "C:\MonitorAgent\dsc-log.txt" -Append

        $fileIsComplete = (Test-Path C:\MonitorAgent\MonitorAgent.zip)
    }catch{
        $_ | Out-File "C:\MonitorAgent\dsc-log.txt" -Append
    }
}while (!$fileIsComplete)

Expand-Archive -LiteralPath C:\MonitorAgent\MonitorAgent.zip -DestinationPath C:\MonitorAgent\bin -Force


# Find the Product Code (IdentifyingNumber) so we know what to uninstall (or if we need to uninstall)
$wmiExporter = Get-WmiObject Win32_Product | Where-Object { $_.Name -eq "WMI Exporter" }
if ($null -ne $wmiExporter)
{
    # Uninstall wmi_exporter from the node machine if it's there, because it's not signed
    Write-Output "Uninstalling unsigned wmi_exporter..."
    msiexec /x $wmiExporter.IdentifyingNumber /qn
}

# Remove the msi file from the machine if it exists
if (Test-Path "C:\wmi_exporter-*.msi")
{
    Remove-Item "C:\wmi_exporter-*.msi"
}

Expand-Archive -LiteralPath C:\Patches\MonitorAgent.Zip -DestinationPath C:\Patches -Force
