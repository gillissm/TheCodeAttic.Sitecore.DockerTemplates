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

3. Start the containers via:

```powershell
docker-compose up -d
```

1. Once the containers are online you will need to login into the CM and execute **Populate Solr Managed Schema** before proceeding with additional development. This only needs done one time or each time you clear your Solr data folder.

2. Stop the containers when you are done by running:

```powershell
docker-compose down
```
