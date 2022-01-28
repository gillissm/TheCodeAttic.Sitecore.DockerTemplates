[CmdletBinding()]
Param (
    
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]
    $LicenseXmlPath,
    
    [string]
    $HostName = "sc.localhost",

    # We do not need to use [SecureString] here since the value will be stored unencrypted in .env,
    # and used only for transient local example environment.
    [string]
    $SitecoreAdminPassword = "Password12345",
    
    # We do not need to use [SecureString] here since the value will be stored unencrypted in .env,
    # and used only for transient local example environment.
    [string]
    $SqlSaPassword = "Password12345",
    
    [string]
    $CdHost = "cd.$HostName",
    
    [string]
    $CmHost = "cm.$HostName",
    
    [string]
    $IdHost = "id.$HostName",

    [string]
    $HorizonHost = "hrz.$HostName",

    [string]
    $SolrPort = 8994
)

$ErrorActionPreference = "Stop";
[boolean]$RootCertificateCreated = $false;

# KEEP
function Add-WindowsHostsFileEntries {
    param(
        [string]$EnvFilePath,
        [string]$Topology,
        [string]$CdHost,
        [string]$CmHost,
        [string]$IdHost,
        [string]$HrzHost,
        [string]$RenderingHost
    )
    
    Write-Information -MessageData "Starting adding Windows hosts file entries..." -InformationAction Continue
    
    @("$CdHost", "$CmHost", "$IdHost", $HrzHost, $RenderingHost) | ForEach-Object { if ($_ -ne '') { Write-Host "Host Entry for $_"; Add-HostsEntry "$_"; } }

    Write-Information -MessageData "Finish adding Windows hosts file entries." -InformationAction Continue
}

# KEEP
function Create-Certificates {
    param(
        [string]$CertDataFolder,
        [string]$CdHost,
        [string]$CmHost,
        [string]$IdHost,
        [string]$HrzHost,
        [string]$RenderingHost
    )
    
    Write-Information -MessageData "Starting create certificates..." -InformationAction Continue
    
    $dnsNames = @("$CdHost", "$CmHost", "$IdHost", $HrzHost, $RenderingHost)
    	
    # Check that Certificate or Key files already exist in the $CertDataFolder 
    $existingCertificateFiles = Get-ChildItem "$CertDataFolder\*" -Include *.crt, *.key
	
    if (-not $existingCertificateFiles) {
		
        # Create Root Certificate file
        $rootKey = Create-RSAKey -KeyLength 4096
        $rootCertificate = Create-SelfSignedCertificate -Key $rootKey
        Create-CertificateFile -Certificate $rootCertificate -OutCertPath "$CertDataFolder\RootCA.crt"
		
        # Create Certificate and Key files for each Sitecore role
        $dnsNames | ForEach-Object {
            if ($_ -ne '') {
                $selfSignedKey = Create-RSAKey
                $certificate = Create-SelfSignedCertificateWithSignature -Key $selfSignedKey -CommonName $_ -DnsName $_ -RootCertificate $rootCertificate
                Create-KeyFile -Key $selfSignedKey -OutKeyPath "$CertDataFolder\$_.key"
                Create-CertificateFile -Certificate $certificate -OutCertPath "$CertDataFolder\$_.crt"
            }
        }
		
        Write-Information -MessageData "Finish creating certificates." -InformationAction Continue
        return $true
    }
    else {
        Write-Information -MessageData "Certificate files already exist." -InformationAction Continue
        return $false
    }
}

# KEEP
function Update-CertsConfigFile {
    param(
        [string]$CertDataFolder,
        [string]$CdHost,
        [string]$CmHost,
        [string]$IdHost,
        [string]$HrzHost,
        [string]$RenderingHost
    )
	
    $certsConfigFile = Join-Path (Split-Path $CertDataFolder -Parent) "config\dynamic\certs_config.yaml"
    $certificatePath = "C:\etc\traefik\certs\"
	
    $customHostNames = @("$CdHost", "$CmHost", "$IdHost", $HrzHost, $RenderingHost)

    $newFileContent = @("tls:", "  certificates:")

    foreach ($customHostName in $customHostNames) {
        if ($customHostName -ne '') {
            $newFileContent += "    - certFile: " + $certificatePath + $customHostName + ".crt"
            $newFileContent += "      keyFile: " + $certificatePath + $customHostName + ".key"
        }
    }
	
    if (!(Test-Path $certsConfigFile)) {
        New-Item -ItemType File -Path $certsConfigFile
    }

    # Clear certs_config.yaml file
    Clear-Content -Path $certsConfigFile
	
    # Setting new content to the certs_config.yaml file
    $newFileContent | Set-Content $certsConfigFile
	
    Write-Information -MessageData "certs_config.yaml file was successfully updated." -InformationAction Continue
}

# KEEP
function InstallModule {
    param(
        [string]$ModuleName,
        [string]$ModuleVersion,
        [string]$RepositoryName
    )

    $moduleInstalled = Get-InstalledModule -Name $ModuleName -RequiredVersion $ModuleVersion -AllowPrerelease -ErrorAction SilentlyContinue
    if (-not $moduleInstalled) {
        Write-Host "Installing '$ModuleName'" -ForegroundColor Green
        Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -AllowPrerelease -Repository $RepositoryName -Scope CurrentUser
    }
}

# KEEP
function Invoke-ComposeInit {
    Write-Host "Starting the Init Process '$moduleName'..." -ForegroundColor Green
    
    if (-not (Test-Path $LicenseXmlPath)) {
        throw "Did not find $LicenseXmlPath"
    }
    if (-not (Test-Path $LicenseXmlPath -PathType Leaf)) {
        throw "$LicenseXmlPath is not a file"
    }
    $LicenseXmlPath = (Get-Item $LicenseXmlPath).Directory.FullName
    
    # Check for Sitecore Gallery
    Import-Module PowerShellGet
    $SitecoreGallery = Get-PSRepository | Where-Object { $_.SourceLocation -eq "https://sitecore.myget.org/F/sc-powershell/api/v2" }
    if (-not $SitecoreGallery) { 
        Write-Host "Adding Sitecore PowerShell Gallery..." -ForegroundColor Green 
        Register-PSRepository -Name SitecoreGallery -SourceLocation "https://sitecore.myget.org/F/sc-powershell/api/v2" -InstallationPolicy Trusted
        $SitecoreGallery = Get-PSRepository -Name SitecoreGallery
    }
    
    # Install and Import SitecoreDockerTools
    $moduleName = "SitecoreDockerTools"
    $repositoryName = $SitecoreGallery.Name

    $module = Find-Module -Name $moduleName -Repository $repositoryName
    $latestVersion = $module.Version
    $importModuleCommand = "Import-Module $moduleName -RequiredVersion $latestVersion"

    InstallModule -ModuleName $moduleName -ModuleVersion $latestVersion -RepositoryName $repositoryName
    
    Write-Host "Importing '$moduleName'..." -ForegroundColor Green
    Invoke-Expression $importModuleCommand
    
    Write-Host "Uncomment .env" -ForegroundColor Green
    Copy-Item -Path ".\Project.env" -Destination ".\.env"
    
    Write-Information -MessageData "Starting populating env file variables..." -InformationAction Continue

    Set-EnvFileVariable "SITECORE_ADMIN_PASSWORD" -Value $SitecoreAdminPassword
    Set-EnvFileVariable "SQL_SA_PASSWORD" -Value $SqlSaPassword
    Set-EnvFileVariable "TELERIK_ENCRYPTION_KEY" -Value (Get-SitecoreRandomString 128 -DisallowSpecial)
    Set-EnvFileVariable "MEDIA_REQUEST_PROTECTION_SHARED_SECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)
    Set-EnvFileVariable "SITECORE_IDSECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)

    $idCertPassword = Get-SitecoreRandomString 12 -DisallowSpecial
    Set-EnvFileVariable "SITECORE_ID_CERTIFICATE" -Value (Get-SitecoreCertificateAsBase64String -DnsName $HostName -Password (ConvertTo-SecureString -String $idCertPassword -Force -AsPlainText) -KeyLength 2048)
    Set-EnvFileVariable "SITECORE_ID_CERTIFICATE_PASSWORD" -Value $idCertPassword

    Set-EnvFileVariable "SITECORE_LICENSE_LOCATION" -Value $LicenseXmlPath
    Set-EnvFileVariable "CD_HOST" -Value $CdHost
    Set-EnvFileVariable "CM_HOST" -Value $CmHost
    Set-EnvFileVariable "ID_HOST" -Value $IdHost
    Set-EnvFileVariable "HRZ_HOST" -Value $HorizonHost
    Set-EnvFileVariable "RENDERING_HOST" -Value $HostName
    
    Set-EnvFileVariable "SOLR_PORT" -Value $SolrPort

    # JSS_EDITING_SECRET
    # Populate it for the Next.js local environment as well
    $jssEditingSecret = Get-SitecoreRandomString 64 -DisallowSpecial
    Set-EnvFileVariable "JSS_EDITING_SECRET" -Value $jssEditingSecret
    if (!(Test-Path "../src/rendering/.env")) {
        New-Item -ItemType File -Path "../src/rendering/.env"
    }
    Set-EnvFileVariable "JSS_EDITING_SECRET" -Value $jssEditingSecret -Path "../src/rendering/.env"

    # JSS_SC_DEPLOYMENT_SECRET
    $jssDeploySecret = Get-SitecoreRandomString 64 -DisallowSpecial
    Set-EnvFileVariable "JSS_SC_DEPLOYMENT_SECRET" -Value $jssDeploySecret
    if (!(Test-Path "../src/rendering/scjssconfig.json")) {
        New-Item -ItemType File -Path "../src/rendering/scjssconfig.json"
    }
    Set-EnvFileVariable "deploysecret" -Value $jssDeploySecret -Path "../src/rendering/scjssconfig.json"


    $CertDataFolder = '.\data\traefik\certs'
    if (!(Test-Path $CertDataFolder)) {
        Write-Warning -Message "The certificate '$CertDataFolder' path isn't valid. Please, specify another path for certificates."
        return
    }
        
    # Configure TLS/HTTPS certificates
    $RootCertificateCreated = Create-Certificates -CertDataFolder $CertDataFolder -CdHost $CdHost -CmHost $CmHost -IdHost $IdHost -HrzHost $HorizonHost -RenderingHost $HostName
        
    # The update for the certs_config.yaml file is if Certificates were created for the custom hostnames.
    if ($RootCertificateCreated) {
        Update-CertsConfigFile -CertDataFolder $CertDataFolder -CdHost $CdHost -CmHost $CmHost -IdHost $IdHost -HrzHost $HorizonHost -RenderingHost $HostName
    }

    # Install Root Certificate if it was created
    if ($RootCertificateCreated) {
        Import-Certificate -FilePath "$CertDataFolder\RootCA.crt" -CertStoreLocation "Cert:\LocalMachine\Root"
    }
        
    # Add Windows hosts file entries
    Add-WindowsHostsFileEntries -CdHost $CdHost -CmHost $CmHost -IdHost $IdHost -HrzHost $HorizonHost -RenderingHost $HostName
}

$logFilePath = Join-Path -path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "compose-init-$(Get-date -f 'yyyyMMddHHmmss').log";
Invoke-ComposeInit *>&1 | Tee-Object $logFilePath