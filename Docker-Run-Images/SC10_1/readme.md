# Notes for Success

## STEPS

1. Authenticate against the image registry by running the following command:

```powershell
docker login -u <USER NAME> -p <PASSWORD OR TOKEN> <REGISTRY>
```

2. Run the init.ps1 with the following parameters:

```powershell
.\init.ps1 `
-LicenseXmlPath C:\Sitcore-Versions\license\ `
-ComposeProjectName TheCodeAttic.RainflyAdventures `
-CMHost cm.rainflyadventures.test `
-CDHost rainflyadventures.test `
-IDHost id.rainflyadventures.test

```

If the setup includes horizon you must use either of the following additional parameters _-HorizonHost_ or _-IncludeHorizon_.

3. Start the containers via:

```powershell
docker-compose up -d
```

1. Once the containers are online you will need to login into the CM and execute **Populate Solr Managed Schema** before proceeding with additional development. This only needs done one time or each time you clear your Solr data folder.

2. Stop the containers when you are done by running:

```powershell
docker-compose down
```

## Optional Steps

If the environment is to leverage Sitecore Horizon, then the following must be included in the as part of the parameter set for _init.ps1_.

```powershell
.\init.ps1 `
-LicenseXmlPath C:\Sitcore-Versions\license\ `
-ComposeProjectName TheCodeAttic.RainflyAdventures `
-CMHost cm.rainflyadventures.test `
-CDHost rainflyadventures.test `
-IDHost id.rainflyadventures.test `
-HorizonHost hrz.rainflyadventures.test

# OR

.\init.ps1 `
-LicenseXmlPath C:\Sitcore-Versions\license\ `
-ComposeProjectName TheCodeAttic.RainflyAdventures `
-CMHost cm.rainflyadventures.test `
-CDHost rainflyadventures.test `
-IDHost id.rainflyadventures.test `
-IncludeHorizon

# OR 

.\init.ps1 `
-LicenseXmlPath C:\Sitcore-Versions\license\ `
-ComposeProjectName TheCodeAttic.RainflyAdventures `
-CMHost cm.rainflyadventures.test `
-CDHost rainflyadventures.test `
-IDHost id.rainflyadventures.test `
-HorizonHost hrz.rainflyadventures.test `
-IncludeHorizon
```
