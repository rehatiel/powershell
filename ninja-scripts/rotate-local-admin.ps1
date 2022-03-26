#####################################################################
#Script variables set below:
#Do not modify these settings
$ChangeAdminUsername = $true
$NewAdminUsername = "mspadmin"
#####################################################################
#Import needed libraries
add-type -AssemblyName System.Web
#This is the process we'll be perfoming to set the admin account.
$LocalAdminPassword = [System.Web.Security.Membership]::GeneratePassword(24,5)
If($ChangeAdminUsername -eq $false) {
Set-LocalUser -name "Administrator" -Password ($LocalAdminPassword | ConvertTo-SecureString -AsPlainText -Force) -PasswordNeverExpires:$true
} else {
$ExistingNewAdmin = get-localuser | Where-Object {$_.Name -eq $NewAdminUsername}
if(!$ExistingNewAdmin){
write-host "Creating new user" -ForegroundColor Yellow
New-LocalUser -Name $NewAdminUsername -Password ($LocalAdminPassword | ConvertTo-SecureString -AsPlainText -Force) -PasswordNeverExpires:$true
Add-LocalGroupMember -Group Administrators -Member $NewAdminUsername
Disable-LocalUser -Name "Administrator"
}
else{
    write-host "Updating admin password" -ForegroundColor Yellow
   set-localuser -name $NewAdminUsername -Password ($LocalAdminPassword | ConvertTo-SecureString -AsPlainText -Force)
}
}
if($ChangeAdminUsername -eq $false ) { $username = "Administrator" } else { $Username = $NewAdminUsername }
 
#Now to update the custom data field in NinjaRMM
Ninja-Property-Set localAdminPassword $LocalAdminPassword
