# Notes for Success

This template provides the basic file structure and docker files to support a Sitecore 10.2 XM environment for headless development. It has been built in a manner to support commiting into a repository for a team project. Services/roles that will be created are CM, ID, Solr, SQL, Horizon, and a Nodejs for the headless site.

After the creation of project you will need to update the following fields in the **/docker/Project.env**. These fields need set once and should be re-usable by all users of the solution when committed to a repository.

```text
# SET THE FOLLOWING MANUALLY - to allow for reuse by all users of the project repository
## Image values should always include the tag
## Image values should NEVER start with a slash, ' / '
SOLR_INIT_IMAGE=
SOLR_IMAGE=
MSSQL_INIT_IMAGE=
MSSQL_IMAGE=
CM_IMAGE=
NODEJS_IMAGE=

## Private Registry, must end with slash ( / )
###Used for CM, MSSQL-INIT,
PROJECT_REGISTRY=thecodeatticimages.azurecr.io/rainflyadventures/

### Used for SOLR-INIT, SOLR,  MSSQL, RENDERING(NODEJS)
BASE_REGISTRY=thecodeatticimages.azurecr.io/sc-base/
```

Most of the other fields will be populated when running the ```init.ps1``` before starting the environment.

## STEPS

The following are the steps to follow to get up and running with the environment. (The commands have been simplified from earlier versions of the script.)

1. Authenticate against the image registry by running the following command:

```powershell
docker login -u <USER NAME> -p <PASSWORD OR TOKEN> <REGISTRY>
```

2. Run the init.ps1 with the following parameters:

```powershell
.\init.ps1 `
-LicenseXmlPath C:\Sitcore-Versions\license\license.xml `
-HostName rainflytest.com

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