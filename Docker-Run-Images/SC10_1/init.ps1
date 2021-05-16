#Requires -RunAsAdministrator

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $LicenseXmlPath,
    
    [Parameter(Mandatory = $true)]
    [string]
    $ComposeProjectName,
    
    # We do not need to use [SecureString] here since the value will be stored unencrypted in .env,
    # and used only for transient local example environment.
    [string]
    $SitecoreAdminPassword = "Password12345",
    
    # We do not need to use [SecureString] here since the value will be stored unencrypted in .env,
    # and used only for transient local example environment.
    [string]
    $SqlSaPassword = "Password12345",

    [string]
    $CMHost = "cm.local",

    [string]
    $CDHost = "cd.local",

    [string]
    $IDHost = "id.local",

    # URL for horizon editing interface, should be a subdomain of the CM.
    [string]
    $HorizonHost="hrz.cm.local",

    [string]
    $SolrPort = "8995",

    # Previous verion: "10.0.5"
    # default to latest: 10.1.4
    [string]
    $dockerToolsVersion = "10.1.4",

    # Relative path to the docker-compose file of where data mounts can be found
    [string]
    $relativeDataPath = ".\data",

    # Relative path to source code for deployment, directory would be the target of custom code build output
    # Default: .\src
    [string]
    $relativeSourcePath = ".\src",

    # When included will set values for Horizon Host
    [switch]
    $IncludeHorizion
)

$ErrorActionPreference = "Stop";

if (-not (Test-Path $LicenseXmlPath)) {
    throw "Did not find $LicenseXmlPath"
}


# Check for Sitecore Gallery
Import-Module PowerShellGet
$SitecoreGallery = Get-PSRepository | Where-Object { $_.SourceLocation -eq "https://sitecore.myget.org/F/sc-powershell/api/v2" }
if (-not $SitecoreGallery) {
    Write-Host "Adding Sitecore PowerShell Gallery..." -ForegroundColor Green 
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2 -InstallationPolicy Trusted
    $SitecoreGallery = Get-PSRepository -Name SitecoreGallery
}
# Install and Import SitecoreDockerTools 
Remove-Module SitecoreDockerTools -ErrorAction SilentlyContinue
if (-not (Get-InstalledModule -Name SitecoreDockerTools -RequiredVersion $dockerToolsVersion -ErrorAction SilentlyContinue)) {
    Write-Host "Installing SitecoreDockerTools..." -ForegroundColor Green
    Install-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion -Scope CurrentUser -Repository $SitecoreGallery.Name
}
Write-Host "Importing SitecoreDockerTools..." -ForegroundColor Green
Import-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion

###############################
# Populate the environment file
###############################

Write-Host "Uncomment .env" -ForegroundColor Green
Copy-Item -Path ".\Project.env" -Destination ".\.env"

Write-Host "Populating required .env file variables..." -ForegroundColor Green

# SITECORE_ADMIN_PASSWORD
Set-EnvFileVariable "SITECORE_ADMIN_PASSWORD" -Value $SitecoreAdminPassword

# SQL_SA_PASSWORD
Set-EnvFileVariable "SQL_SA_PASSWORD" -Value $SqlSaPassword

# TELERIK_ENCRYPTION_KEY = random 64-128 chars
Set-EnvFileVariable "TELERIK_ENCRYPTION_KEY" -Value (Get-SitecoreRandomString 128)

# MEDIA_REQUEST_PROTECTION_SHARED_SECRET
Set-EnvFileVariable "MEDIA_REQUEST_PROTECTION_SHARED_SECRET" -Value (Get-SitecoreRandomString 64)

# SITECORE_IDSECRET = random 64 chars
Set-EnvFileVariable "SITECORE_IDSECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)

# SITECORE_ID_CERTIFICATE
$idCertPassword = Get-SitecoreRandomString 12 -DisallowSpecial
Set-EnvFileVariable "SITECORE_ID_CERTIFICATE" -Value (Get-SitecoreCertificateAsBase64String -DnsName "local" -Password (ConvertTo-SecureString -String $idCertPassword -Force -AsPlainText))

# SITECORE_ID_CERTIFICATE_PASSWORD
Set-EnvFileVariable "SITECORE_ID_CERTIFICATE_PASSWORD" -Value $idCertPassword

# SITECORE_LICENSE_FOLDER
Set-EnvFileVariable "SITECORE_LICENSE_FOLDER" -Value $LicenseXmlPath

# CM_HOST
Set-EnvFileVariable "CM_HOST" -Value $CMHost
#CD_HOST
Set-EnvFileVariable "CD_HOST" -Value $CDHost

#ID_HOST
Set-EnvFileVariable "ID_HOST" -Value $IDHost

if($IncludeHorizion -or $HorizonHost -ne ""){
    # HRZ_HOST
    Set-EnvFileVariable "HRZ_HOST" -Value $HorizonHost
}

# COMPOSE_PROJECT_NAME
Set-EnvFileVariable "COMPOSE_PROJECT_NAME" -Value $ComposeProjectName

# SolrPort
Set-EnvFileVariable "SOLR_PORT" -Value $SolrPort

# REPORTING_API_KEY = random 64-128 chars
Set-EnvFileVariable "REPORTING_API_KEY" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)

Set-EnvFileVariable "LOCAL_DATA_PATH" -Value $relativeDataPath

Set-EnvFileVariable "LOCAL_DEPLOY_PATH" -Value $relativeSourcePath

##################################
# Configure TLS/HTTPS certificates
##################################

Push-Location "$relativeDataPath\traefik\certs"
try {
    $mkcert = ".\mkcert.exe"
    if ($null -ne (Get-Command mkcert.exe -ErrorAction SilentlyContinue)) {
        # mkcert installed in PATH
        $mkcert = "mkcert"
    } elseif (-not (Test-Path $mkcert)) {
        Write-Host "Downloading and installing mkcert certificate tool..." -ForegroundColor Green 
        Invoke-WebRequest "https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-windows-amd64.exe" -UseBasicParsing -OutFile mkcert.exe
        if ((Get-FileHash mkcert.exe).Hash -ne "1BE92F598145F61CA67DD9F5C687DFEC17953548D013715FF54067B34D7C3246") {
            Remove-Item mkcert.exe -Force
            throw "Invalid mkcert.exe file"
        }
    }
   
   if($IncludeHorizion -or $HorizonHost -ne ""){
    Write-Host "Generating Traefik TLS certificates..." -ForegroundColor Green
    & $mkcert -install
    & $mkcert -cert-file cm.crt -key-file cm.key "$CMHost"
    & $mkcert -cert-file cd.crt -key-file cd.key "$CDHost"
    & $mkcert -cert-file id.crt -key-file id.key "$IDHost"
    & $mkcert -cert-file hrz.crt -key-file hrz.key "$HorizonHost"
   }
   else{
    Write-Host "Generating Traefik TLS certificates..." -ForegroundColor Green
    & $mkcert -install
    & $mkcert -cert-file cm.crt -key-file cm.key "$CMHost"
    & $mkcert -cert-file cd.crt -key-file cd.key "$CDHost"
    & $mkcert -cert-file id.crt -key-file id.key "$IDHost"
   }
}
catch {
    Write-Host "An error occurred while attempting to generate TLS certificates: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}

################################
# Add Windows hosts file entries
################################

Write-Host "Adding Windows hosts file entries..." -ForegroundColor Green

Add-HostsEntry $CMHost
Add-HostsEntry $CDHost
Add-HostsEntry $IDHost
if($IncludeHorizion -or $HorizonHost -ne ""){
    Add-HostsEntry $HorizonHost
}


Write-Host ""
Write-Host "CM url $CMHost" -BackgroundColor Gray -ForegroundColor Magenta
Write-Host "CD url $CDHost" -BackgroundColor Gray -ForegroundColor Magenta
if($IncludeHorizion -or $HorizonHost -ne ""){
    Write-Host "Horizon url $HorizonHost" -BackgroundColor Gray -ForegroundColor Magenta
}

Write-Host "Done!" -ForegroundColor Green