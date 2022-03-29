#####################################################################
$APIKEy = "ITGLUEAPIKEY"
$APIEndpoint = "https://api.itglue.com"
#orgID is the default.  Assuming you've set this in Ninja, the default will be overridden with the orgID of your client.
#It is recommended you make the default orgID the ID of your company.  (Example: https://acme.itglue.com/3274882, your ID would be 3274882)
#All of these variables should be changed before using this script.  I assume no responsibility if you lock yourself out :)
$orgID = "1234567"
$AdminUser = "MSPAdmin"
$NinjaTemplate = "CHANGEME"
$NinjaDocument = "CHANGEME"
$NinjaEnabledAttribute = "EnableDomainAdminPasswordRotation"
$NinjaOrgIDAttribute = "ITGlueOrganizationID"
#####################################################################
#Confirming password rotation is enabled per client documentation
$EnableDomainRotation = Ninja-Property-Docs-Get $NinjaTemplate $NinjaDocument $NinjaEnabledAttribute
If ($EnableDomainRotation -eq '0'){
    #Password rotation not enabled, exitting script immediately.
    Write-Host "Password rotation disabled in Ninja"
    break
} else {
    #Now we'll check NinjaRMM for the orgID document field.  If it's not found, your default company will be used
$orgIDNinja = Ninja-Property-Docs-Get $NinjaTemplate $NinjaDocument $NinjaOrgIDAttribute
    If (-not ($null -eq $orgIDNinja)){
        Write-Host "Org ID found!"
        #Assigning the Ninja specified orgID to the variable. 
        $orgID = Ninja-Property-Docs-Get $NinjaTemplate $NinjaDocument $NinjaOrgIDAttribute
        Remove-Variable orgIDNinja
    } else {
        Write-Host "No orgID found, we will still attempt to write to Ninja"
    }
}
#####################################################################
#Grabbing ITGlue Module, and installing. Nuget is required and isn't typically loaded on servers.
Find-PackageProvider -Name "NuGet" -AllVersions -Force
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
If(Get-Module -ListAvailable -Name "ITGlueAPI") {Import-module ITGlueAPI} Else { install-module ITGlueAPI -Force; import-module ITGlueAPI}
#Settings IT-Glue logon information
Add-ITGlueBaseURI -base_uri $APIEndpoint
Add-ITGlueAPIKey $APIKEy
add-type -AssemblyName System.Web
#This is the process we'll be perfoming to set the admin account.
$AdminPW = [System.Web.Security.Membership]::GeneratePassword(24,5)
#Check for the existance of the $AdminUser
if ((Get-ADUser -Filter *).Name -eq $AdminUser){
    Set-ADAccountPassword -Identity $AdminUser -NewPassword ($AdminPW | ConvertTo-SecureString -AsPlainText -Force)
    }else{
        New-ADUser -Name $AdminUser -Accountpassword ($AdminPW | ConvertTo-SecureString -AsPlainText -Force) -PasswordNeverExpires:$true -Enabled $true
        Add-ADGroupMember -Identity "Administrators" -Members $AdminUser
    }
#The script uses the following line to find the correct asset by serialnumber, match it, and connect it if found. Don't want it to tag at all? Comment it out by adding #
 $TaggedResource = (Get-ITGlueConfigurations -organization_id $orgID -filter_serial_number (get-ciminstance win32_bios).serialnumber).data | Select-Object -Last 1
 $PasswordObjectName = "$($Env:COMPUTERNAME) - Domain Administrator Account"
 $PasswordObject = @{
   type = 'passwords'
     attributes = @{
             name = $PasswordObjectName
             username = $AdminUser
             password = $AdminPW
             notes = "Domain Admin Password for $($Env:COMPUTERNAME)"
     }
 }
 if($TaggedResource){ 
     $Passwordobject.attributes.Add("resource_id",$TaggedResource.Id)
     $Passwordobject.attributes.Add("resource_type","Configuration")
 }
 
# #Now we'll check if it already exists, if not. We'll create a new one.
 $ExistingPasswordAsset = (Get-ITGluePasswords -filter_organization_id $orgID -filter_name $PasswordObjectName).data
 #If the Asset does not exist, we edit the body to be in the form of a new asset, if not, we just upload.
 if(!$ExistingPasswordAsset){
 $ITGNewPassword = New-ITGluePasswords -organization_id $orgID -data $PasswordObject
 } else {
 $ITGNewPassword = Set-ITGluePasswords -id $ExistingPasswordAsset.id -data $PasswordObject
 }
#Now we will write this data to the NinjaRMM custom field for this server.
Ninja-Property-Set domainadminpassword $AdminPW
Remove-Variable AdminUser; Remove-Variable AdminPW; Remove-Variable APIkey;
