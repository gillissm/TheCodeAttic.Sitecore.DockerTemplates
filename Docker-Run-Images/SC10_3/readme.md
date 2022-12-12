# Notes for Success

## Release Notes

* Sitecore has discontined the Horizon editor, thus no image or setup logic exists for this feature
* There has been slight modification to the init script from previous versions see the [Steps](#steps) section for usage
* Running is setup for XM1 scenarios

## STEPS

1. Authenticate against the image registry by running the following command:

```powershell
docker login -u <USER NAME> -p <PASSWORD OR TOKEN> <REGISTRY>
```

2. Run the init.ps1 with one of the following options

```powershell
# Set a hostname only which created the following URLs: cm.$HOSTNAME, id.$HOSTNAME, and CD will server up on $HOSTNAME
.\init.ps1 `
-LicenseXmlPath C:\Sitcore-Versions\license\license.xml `
-ComposeProjectName TheCodeAttic.RainflyAdventures `
-HostName rainflyadventures.test
```

OR to define specific URLs for each service

```powershell
# Set unique URLs for CM, ID, and CD

.\init.ps1 `
-LicenseXmlPath C:\Sitcore-Versions\license\license.xml `
-ComposeProjectName TheCodeAttic.RainflyAdventures `
-CMHost cm.rainflyadventures.test `
-CDHost rainflyadventures.test `
-IDHost id.rainflyadventures.test
```

3. Start the containers via:

```powershell
docker-compose up -d
```

4. Once the containers are online you will need to login into the CM and execute **Populate Solr Managed Schema** before proceeding with additional development. This only needs done one time or each time you clear your Solr data folder.

5. Stop the containers when you are done by running:

```powershell
docker-compose down
```
