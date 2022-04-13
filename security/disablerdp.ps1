#Variables
$RDPStatus = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections
If ($RDPStatus -eq "0"){
    Write-Host "RDP Enabled - disabling via registry and Windows firewall"
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -name “fDenyTSConnections” -Value 1
    Disable-NetFirewallRule -DisplayGroup “Remote Desktop”
} else {
    Write-Host "Windows RDP disabled, exiting."
}
