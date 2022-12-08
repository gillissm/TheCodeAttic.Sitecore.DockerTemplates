# Building an Asset Image from a Sitecore Package

The following is a working sample on how to convert a Sitecore Package into an asset image for docker.

It has been configured to create an asset image for [Sitecore PowerShell Extensions 6.4](https://github.com/SitecorePowerShell/Console/releases/tag/6.4).

Depending on the module not all steps maybe required.

## Steps

### Steps for asset image creation

1. Extract the Sitecore package
2. Open and extract the *package.zip*
3. Create the following folder structure next to a docker build file

```graph
\---module
    +---content
    |   +---cd
    |   \---cm
    \---db
```

4. Navigate to */package/files/*, copy the contents to the proper content sub-directory depending on which servers you will need the file assets.

5. As a sibling to the module directory, create a new dockerfile with the following contents

```dockerfile
FROM mcr.microsoft.com/windows/nanoserver:20H2 AS build

# Copy assets into the image, keeping the folder structure
COPY \ .\
```

6. From the prompt perform an image build

```powershell
docker build . --tag <registery>/<repository>/<name>:<tag>

# Example
# docker build . --tag thecodeatticimages.azurecr.io/paragon/base-assets/spe:latest
```

7. Double check the asset image via

```powershell
docker run -it <image name>

# Example
# docker run -it thecodeatticimages.azurecr.io/paragon/base-assets/spe:latest
```

8. Push to the registry and start using as part of your docker pipeline.

### Additional Steps For Database Changes

1. Download the Sitecore Azure Toolkit
2. Extract the tookit archive
3. Import the toolkit modules

```powershell
Import-Module .\tools\Sitecore.Cloud.Cmdlets.psm1
Import-Module .\tools\Sitecore.Cloud.Cmdlets.dll
```

4. Convert the Sitecore package

```powershell
ConvertTo-SCModuleWebDeployPackage -Path "<path to package>" -Destination "<path to were to put the scwdp>"
```

5. Expand the deploy package

```powershell
Expand-Archive "<path to the scwdp from step 4>"
```

6. From the contents expanded in step 5, copy any *dacpac* files into *modules/db.

7. Build the image and push to registry for usage.

## References

* https://medium.com/@mitya_1988/how-to-create-a-docker-asset-image-for-your-sitecore-module-58e1f3a47672
* https://www.kayee.nl/2021/07/01/auto-create-a-docker-asset-image-for-your-sitecore-module/