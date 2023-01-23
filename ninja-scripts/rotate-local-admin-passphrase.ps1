#Script variables set below:
$ChangeAdminUsername = $true
$NewAdminUsername = "MSPAdmin"

#####################################################################
#Let's make a password!
add-type -AssemblyName System.Web

#We will attempt to generate a passphrase first.  Requires access to makemeapassword.ligos.net - open source
$LocalAdminPassword = (Invoke-RestMethod -Uri "https://makemeapassword.ligos.net/api/v1/passphrase/plain?pc=1&wc=3&sp=y&minCh=21&maxCh=45&whenNum=EndOfPhrase&whenUp=StartOfWord")
$randomChar = [System.Web.Security.Membership]::GeneratePassword(1,1).ToString() #Generates a random character for complexity requirements
$LocalAdminPassword = -join($LocalAdminPassword.Trim(), $randomChar) #Adds the random character from randomChar to the end of our passphrase

#Let's check to see if there's anything in our LocalAdminPassword variable
if($LocalAdminPassword.Length -le 20){
    Write-Warning "Insufficient password length, using random characters"
    $LocalAdminPassword = [System.Web.Security.Membership]::GeneratePassword(24,5) #No password found, populating with randomly generated password.
} elseif($LocalAdminPassword.Length -le 20){
    Write-Error "Insufficient password length, aborting."
    break
}

#####################################################################
if($ChangeAdminUsername -eq $false) {
    Set-LocalUser -name "Administrator" -Password ($LocalAdminPassword | ConvertTo-SecureString -AsPlainText -Force) -PasswordNeverExpires:$true
} else {
    $ExistingNewAdmin = get-localuser | Where-Object {$_.Name -eq $NewAdminUsername}
    if(!$ExistingNewAdmin){
        Write-Host "Creating new user" -ForegroundColor Yellow
        New-LocalUser -Name $NewAdminUsername -Password ($LocalAdminPassword | ConvertTo-SecureString -AsPlainText -Force) -PasswordNeverExpires:$true
        Add-LocalGroupMember -Group Administrators -Member $NewAdminUsername
        Disable-LocalUser -Name "Administrator"
    }
    else{
        Write-Host "Updating admin password" -ForegroundColor Yellow
        set-localuser -name $NewAdminUsername -Password ($LocalAdminPassword | ConvertTo-SecureString -AsPlainText -Force)
    }
}

#Now to update the custom data field in NinjaRMM
Ninja-Property-Set localAdminPassword $LocalAdminPassword
