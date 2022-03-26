#This script uses paexec instead of psexec
workflow remove-cylance {
    #Script Variables
    $cremoval = '\tmp\c-removal'
    $source = 'https://www.poweradmin.com/paexec/paexec.exe'
    $destination = '\tmp\c-removal\paexec.exe'
    mkdir $cremoval
    #Download paexec and extract
    Invoke-WebRequest -Uri $source -OutFile $destination
    #Reset Variables and download SetACL from github
    $source = 'https://github.com/bjonescts/CTS_Powershell_Scripts/raw/main/cylance/tools/SetACL.exe'
    $destination = '\tmp\c-removal\SetACL.exe'
    Invoke-WebRequest -Uri $source -OutFile $destination
    #Execute paexec to disable the Cylance service from starting
    $paexec = '\tmp\c-removal\paexec.exe'
    Invoke-Expression -Command "$paexec -accepteula -h -s sc config cylancesvc start= disabled"
    #Reboot
    Restart-Computer -Wait -Force
    #Modify the protected registry keys
    $setacl = '\tmp\c-removal\SetACL.exe'
    Invoke-Expression -Command "$setacl -on 'HKLM\SOFTWARE\Cylance\Desktop' -ot reg -actn setowner -ownr 'n:Administrators'"
    Invoke-Expression -Command "$setacl -on 'HKLM\SOFTWARE\Cylance\Desktop' -ot reg -actn ace -ace n:Administrators;p:full"
    Set-ItemProperty 'HKLM:\SOFTWARE\Cylance\Desktop' -Name 'SelfProtectionLevel' -Value 1
    #Reboot
    Restart-Computer -Wait -Force
    #Initiate the uninstallation process
    $product = Get-WmiObject win32_product | `
    where{$_.name -eq "Cylance PROTECT"}
    msiexec /x $product.IdentifyingNumber /QN /L*V "C:\cylance.log" REBOOT=R
    }
    remove-cylance
