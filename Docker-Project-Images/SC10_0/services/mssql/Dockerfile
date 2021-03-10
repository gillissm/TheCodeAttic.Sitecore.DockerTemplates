# escape=`

ARG BASE_IMAGE
ARG SOLUTION_IMAGE

FROM ${SOLUTION_IMAGE} as sln
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]


COPY --from=sln \artifacts\db C:\artifacts

# Sitecore base SQL image is SQL 2017, we have a 2019 based dacpac therefore must install updated DacPac tooling, before deploying.
RUN C:\artifacts\DacFramework.msi /q; `
     C:\artifacts\DeployDatabases.ps1 -ResourcesDirectory C:\artifacts; `    
     Remove-Item -Path C:\artifacts -Recurse -Force;

# # Add custom db form local relative reference
# COPY .\artifacts \custom-data
# RUN C:\DeployDatabases.ps1 -ResourcesDirectory C:\custom-data; `
#     Remove-Item -Path C:\custom-data -Recurse -Force;