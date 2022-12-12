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
    $Hostname = "local",

    [string]
    $CMHost = "cm.$Hostname",

    [string]
    $CDHost = "$Hostname",

    [string]
    $IDHost = "id.$Hostname",

    [switch]
    $EnableaGraphQL,

    [string]
    $SolrPort = "8995",

    # Previous verion: "10.0.5"
    # Previous verion: "10.1.4"
    # default to latest: 10.2.7
    [string]
    $dockerToolsVersion = "10.2.7",

    # Relative path to the docker-compose file of where data mounts can be found
    [string]
    $relativeDataPath = ".\data",

    # Relative path to source code for deployment, directory would be the target of custom code build output
    # Default: .\src
    [string]
    $relativeSourcePath = ".\src"
)

$ErrorActionPreference = "Stop";

if (-not (Test-Path $LicenseXmlPath)) {
    throw "Did not find $LicenseXmlPath"
}
if (-not (Test-Path $LicenseXmlPath -PathType Leaf)) {
    throw "$LicenseXmlPath is not a file"
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
Set-EnvFileVariable "SITECORE_LICENSE_FOLDER" -Value (Split-Path $LicenseXmlPath -Parent)

# CM_HOST
Set-EnvFileVariable "CM_HOST" -Value $CMHost
#CD_HOST
Set-EnvFileVariable "CD_HOST" -Value $CDHost
#ID_HOST
Set-EnvFileVariable "ID_HOST" -Value $IDHost

# COMPOSE_PROJECT_NAME
Set-EnvFileVariable "COMPOSE_PROJECT_NAME" -Value $ComposeProjectName

# SolrPort
Set-EnvFileVariable "SOLR_PORT" -Value $SolrPort

Set-EnvFileVariable "LOCAL_DATA_PATH" -Value $relativeDataPath

Set-EnvFileVariable "LOCAL_DEPLOY_PATH" -Value $relativeSourcePath

if($EnableaGraphQL){
    Set-EnvFileVariable "SITECORE_GRAPHQL_ENABLED" -Value "true"
    Set-EnvFileVariable "SITECORE_GRAPHQL_EXPOSEPLAYGROUND" -Value "true"
    Set-EnvFileVariable "SITECORE_GRAPHQL_UPLOADMEDIAOPTIONS_ENCRYPTIONKEY" -Value (Get-SitecoreRandomString 32 -DisallowSpecial)
}

##################################
# Configure TLS/HTTPS certificates
##################################
try {
 
    # Check that Certificate or Key files already exist in the $CertDataFolder 
    $CertDataFolder =  "$relativeDataPath\traefik\certs"
    $existingCertificateFiles = Get-ChildItem "$CertDataFolder\*" -Include *.crt, *.key
        
    if (-not $existingCertificateFiles){
        
        $dnsNames = @("$CDHost", "$CMHost", "$IDHost")

        # Create Root Certificate file
        $rootKey = Create-RSAKey -KeyLength 4096
        $rootCertificate = Create-SelfSignedCertificate -Key $rootKey
        Create-CertificateFile -Certificate $rootCertificate -OutCertPath "$CertDataFolder\RootCA.crt"
        
        # Create Certificate and Key files for each Sitecore role
        $dnsNames | ForEach-Object {
            $selfSignedKey = Create-RSAKey
            $certificate = Create-SelfSignedCertificateWithSignature -Key $selfSignedKey -CommonName $_ -DnsName $_ -RootCertificate $rootCertificate
            Create-KeyFile -Key $selfSignedKey -OutKeyPath "$CertDataFolder\$_.key"
            Create-CertificateFile -Certificate $certificate -OutCertPath "$CertDataFolder\$_.crt"
        }
        
        Write-Information -MessageData "Finish creating certificates for '$Topology' topology." -InformationAction Continue

        $certsConfigFile = "$relativeDataPath\traefik\config\dynamic\certs_config.yaml"
        $certificatePath = "C:\etc\traefik\certs\"
        
        $customHostNames = @("$CdHost", "$CmHost", "$IdHost")
        $newFileContent = @("tls:", "  certificates:")
    
        foreach ($customHostName in $customHostNames){
            $newFileContent +=  "    - certFile: " + $certificatePath + $customHostName + ".crt"
            $newFileContent +=  "      keyFile: " + $certificatePath + $customHostName + ".key"
        }
        
        # Clear certs_config.yaml file
        Clear-Content -Path $certsConfigFile
        
        # Setting new content to the certs_config.yaml file
        $newFileContent | Set-Content $certsConfigFile
        
        Write-Information -MessageData "certs_config.yaml file was successfully updated." -InformationAction Continue

        Import-Certificate -FilePath "$CertDataFolder\RootCA.crt" -CertStoreLocation "Cert:\LocalMachine\Root"
 
    }
    else {
        Write-Information -MessageData "Certificate files already exist for '$Topology' topology." -InformationAction Continue
    } 
}
catch {
    Write-Host "An error occurred while attempting to generate TLS certificates: $_" -ForegroundColor Red
}

################################
# Add Windows hosts file entries
################################

Write-Host "Adding Windows hosts file entries..." -ForegroundColor Green

Add-HostsEntry $CMHost
Add-HostsEntry $CDHost
Add-HostsEntry $IDHost

Write-Host ""
Write-Host "CM url $CMHost" -BackgroundColor Gray -ForegroundColor Magenta
Write-Host "CD url $CDHost" -BackgroundColor Gray -ForegroundColor Magenta

Write-Host "Done!" -ForegroundColor Green