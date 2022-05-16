#--------Variables------------#
$version = "2.0.45" #Current version requested
$cybercnspath = "C:\Program Files (x86)\CyberCNSAgentV2"
#Retrieve the CyberCNS keys from the documents section under the organization
$companyid = (Ninja-Property-Docs-Get 'CyberCNS' 'CYBERCNS' 'CompanyID')
$clientid = (Ninja-Property-Docs-Get 'CyberCNS' 'CYBERCNS' 'ClientID')
$secret = (Ninja-Property-Docs-Get 'CyberCNS' 'CYBERCNS' 'ClientSecret')
$cybercns_agent = "https://example.mycybercns.com/agents/ccnsagent/cybercnsagent.exe" #Link to your cybercnsagent.exe
#-----------------------------#
$installedversion = Get-Content -Path "$cybercnspath\lastagentversion_update.cfg"
if ($installedversion -ge $version) {
    Write-Host "Already updated, exiting."
    break
}
else {
    Write-Host "Removing old version"
    Stop-Service "CyberCNSAgentV2"
    Remove-Service "CyberCNSAgentV2"
    Stop-Process -Name "CyberCNSAgentV2" -Force
    Remove-Item "$cybercnspath" -Recurse -Force
    Write-Host "CyberCNS Removed, proceeding with install"
    
    #Install latest version of CyberCNS
    if ($null -eq $companyid){
        Write-Host "No company ID specified in Ninja, installation aborting."
        break
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; 
    $source = '$cybercns_agent'
    $destination = 'cybercnsagent.exe'
    Invoke-WebRequest -Uri $source -OutFile $destination
    ./cybercnsagent.exe -c $companyid -a $clientid -s $secret -b teamctsv2.mycybercns.com -i LightWeight
    Write-Host "Installation finished"
}
