#################Setting some variables
$MSPRepoName = "changeme"
$MSPRepoWebURL = https://changeme/repository/chocolatey-group/
$ChocoUserDefault = "defaultuser"
$ChocoPassDefault = "changeme"
$NinjaTemplate = "changeme"
$NinjaDocument = "changeme"
$NinjaChocoUser = "chocolateyUsername"
$NinjaChocoPass = "chocolateyPassword"

#################Retrieving password if specified in NinjaRMM
$ChocoUser = Ninja-Property-Docs-Get $NinjaTemplate $NinjaDocument $NinjaChocoUser
$ChocoPass = Ninja-Property-Docs-Get $NinjaTemplate $NinjaDocument $NinjaChocoPass
if ($null -eq $ChocoUser){
  #No user specified, using defaults
  Write-Host "No credentials specified, using defaults."
  $ChocoUser = $ChocoUserDefault
  $ChocoPass = $ChocoPassDefault
} else {
    Write-Host "Found credentials, continuing with installation"
}
if (Test-Path -path c:\ProgramData\chocolatey\choco.exe){
    Write-Host "Chocolatey installed, correcting sources."
    #Remove community
    choco source remove -n="chocolatey"
    #Remove old repo
    choco source remove -n $MSPRepoName
    #Add updated MSP repo
    choco source add -n $MSPRepoName -s $MSPRepoWebURL -u $ChocoUser -p $ChocoPass
} else {

  #Not installed... installing!
  Write-Host "Not installed, proceeding with install."
  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

  #Remove community
  choco source remove -n="chocolatey"

  #Add MSP repo
  choco source add -n $MSPRepoName -s $MSPRepoWebURL -u $ChocoUser -p $ChocoPass
}
