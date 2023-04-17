#####################################################################
$AdminUser = "mspadmin"
#####################################################################
#Getting your new password cooked up
add-type -AssemblyName System.Web
$AdminPW = [System.Web.Security.Membership]::GeneratePassword(24,5)
#Check for the existance of the $AdminUser
if ((Get-ADUser -Filter *).SamAccountName -eq $AdminUser){
    Set-ADAccountPassword -Identity $AdminUser -NewPassword ($AdminPW | ConvertTo-SecureString -AsPlainText -Force)
    }else{
        New-ADUser -Name $AdminUser -Accountpassword ($AdminPW | ConvertTo-SecureString -AsPlainText -Force) -PasswordNeverExpires:$true -Enabled $true
        Add-ADGroupMember -Identity "Administrators" -Members $AdminUser
    }
#Now we will write this data to the NinjaRMM custom field for this server.
Ninja-Property-Set domainadminpassword $AdminPW
#Clearing Variables
Remove-Variable AdminUser; Remove-Variable AdminPW
