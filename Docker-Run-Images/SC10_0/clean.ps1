param(
  [string]
  $datafolderpath = '.\data',
  [switch]
  $skipPrompts,
  [switch]
  $cleanEnv
)

function CleanupDirectory {
  param([string]$relativeDirPath)

  Write-Host "Deleting: $relativeDirPath " -ForegroundColor DarkRed -BackgroundColor Gray
  $dPath = Join-Path $dataPath $relativeDirPath
  Get-ChildItem -Path $dPath -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse
  Write-Host "Completed delete of $relativeDirPath " -ForegroundColor DarkBlue -BackgroundColor Gray
  Write-Host ""
}

function CleanupEnv {
  Write-Host "Resetting the .env file" -ForegroundColor DarkRed -BackgroundColor Gray
  
  Write-Host "Importing SitecoreDockerTools..." -ForegroundColor Green
  Import-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion

  # SITECORE_ADMIN_PASSWORD
  Set-EnvFileVariable "SITECORE_ADMIN_PASSWORD" -Value "Password12345"

  # SQL_SA_PASSWORD
  Set-EnvFileVariable "SQL_SA_PASSWORD" -Value "Password12345"

  # TELERIK_ENCRYPTION_KEY = random 64-128 chars
  Set-EnvFileVariable "TELERIK_ENCRYPTION_KEY" -Value ""

  # MEDIA_REQUEST_PROTECTION_SHARED_SECRET
  Set-EnvFileVariable "MEDIA_REQUEST_PROTECTION_SHARED_SECRET" -Value ""

  # SITECORE_IDSECRET = random 64 chars
  Set-EnvFileVariable "SITECORE_IDSECRET" -Value ""

  # SITECORE_ID_CERTIFICATE
  Set-EnvFileVariable "SITECORE_ID_CERTIFICATE" -Value ""

  # SITECORE_ID_CERTIFICATE_PASSWORD
  Set-EnvFileVariable "SITECORE_ID_CERTIFICATE_PASSWORD" -Value ""

  # SITECORE_LICENSE_FOLDER
  Set-EnvFileVariable "SITECORE_LICENSE_FOLDER" -Value ""

  # CM_HOST
  Set-EnvFileVariable "CM_HOST" -Value "cm.local"

  #CD_HOST
  Set-EnvFileVariable "CD_HOST" -Value "cd.local"

  #ID_HOST
  Set-EnvFileVariable "ID_HOST" -Value "id.local"

  # COMPOSE_PROJECT_NAME
  Set-EnvFileVariable "COMPOSE_PROJECT_NAME" -Value "I-NEED-A-VALUE"

  # SolrPort
  Set-EnvFileVariable "SOLR_PORT" -Value $"8995"

  # REPORTING_API_KEY = random 64-128 chars
  Set-EnvFileVariable "REPORTING_API_KEY" -Value ""

  Set-EnvFileVariable "LOCAL_DATA_PATH" -Value ".\data"

  Set-EnvFileVariable "LOCAL_DEPLOY_PATH" -Value ".\src"

  Write-Host "Completed cleanup of .env " -ForegroundColor DarkBlue -BackgroundColor Gray
  Write-Host ""

}

# Remove all unsused containers, networks, images, volumes
Write-Host "Performing a docker system prune" -ForegroundColor DarkRed -BackgroundColor Gray
docker system prune -f

Write-Host ""

# Root data path
$dataPath = (Join-Path $PSScriptRoot $datafolderpath)


if ($skipPrompts) {
  Write-Host "All data, including databases will be cleaned-up and removed."
  $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Remove all including databases"
  $no = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel", "Cancel the script and take no action"
  $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
  $title = "Skip Prompts"
  $msg = "Confirm that you wish to delete/remove all mounted data? If you continue no prompts will be given,"
  $result = $host.ui.PromptForChoice($title, $msg, $options, 1)
  switch ($result) {
    0 { 
      CleanupDirectory -relativeDirPath "cd/sc-log"
      CleanupDirectory -relativeDirPath "cm/sc-log"
      CleanupDirectory -relativeDirPath "mssql-data"
      CleanupDirectory -relativeDirPath "solr-data"
      CleanupDirectory -relativeDirPath "traefik/certs"
      CleanupDirectory -relativeDirPath ".\src"
    }
    1 { Write-Host "User has choosen to cancel the script. No cleanup actions taken." -ForegroundColor Green -BackgroundColor Gray }
  }
}
else {

  # Generic yes and no prompt options
  $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Delete the files"
  $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Skip deletion of these files"
  $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

  # Clean CD logs
  $title = "CD Log"
  $msg = "Delete CD logs?"
  $result = $host.ui.PromptForChoice($title, $msg, $options, 0)
  switch ($result) {
    0 { 
      CleanupDirectory -relativeDirPath "cd/log"
    }
    1 { Write-Host "Skipping CD logs" -ForegroundColor Green -BackgroundColor Gray }
  }

  # Clean CM logs
  $title = "CM Log"
  $msg = "Delete CM logs?"
  $result = $host.ui.PromptForChoice($title, $msg, $options, 0)
  switch ($result) {
    0 { 
      CleanupDirectory -relativeDirPath "cm/log"
    }
    1 { Write-Host "Skipping CM logs" -ForegroundColor Green -BackgroundColor Gray }
  }

  # Clean SQL
  $title = "SQL Data"
  $msg = "Delete SQL Data?"
  $result = $host.ui.PromptForChoice($title, $msg, $options, 1)
  switch ($result) {
    0 { 
      CleanupDirectory -relativeDirPath "mssql-data"
    }
    1 { Write-Host "Skipping SQL Data" -ForegroundColor Green -BackgroundColor Gray }
  }

  # Clean Solr Indexes
  $title = "Solr Indexes"
  $msg = "Delete Solr Indexes?"
  $result = $host.ui.PromptForChoice($title, $msg, $options, 0)
  switch ($result) {
    0 { 
      CleanupDirectory -relativeDirPath "solr-data"
    }
    1 { Write-Host "Skipping Solr Indexes" -ForegroundColor Green -BackgroundColor Gray }
  }

  # Clean certs
  $title = "Traefik Certs"
  $msg = "Delete Traefik Certs?"
  $result = $host.ui.PromptForChoice($title, $msg, $options, 1)
  switch ($result) {
    0 { 
      CleanupDirectory -relativeDirPath "traefik/certs"
    }
    1 { Write-Host "Skipping Traefik Certs" -ForegroundColor Green -BackgroundColor Gray }
  }


  # Clean Source
  $title = "Source"
  $msg = "Delete custom source?"
  $result = $host.ui.PromptForChoice($title, $msg, $options, 1)
  switch ($result) {
    0 { 
      CleanupDirectory -relativeDirPath ".\src"
    }
    1 { Write-Host "Skipping custom source" -ForegroundColor Green -BackgroundColor Gray }
  }
}

if($cleanEnv){
  # Generic yes and no prompt options
  $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Clean the .env file"
  $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Decline cleaning of the .env file"
  $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

  # Clean .env
  $title = "Reset .env"
  $msg = "Confirm you want to proceed with resetting the .env?"
  $result = $host.ui.PromptForChoice($title, $msg, $options, 1)
  switch ($result) {
    0 { 
      CleanupEnv
    }
    1 { Write-Host "Skipping reset of .env file." -ForegroundColor Green -BackgroundColor Gray }
  }
}