# escape=`

ARG BASE_IMAGE
ARG HRZ_IMAGE

FROM ${HRZ_IMAGE} as hrz
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Add Horizon module
COPY --from=hrz \module\db \horizon_integration_data

RUN C:\DeployDatabases.ps1 -ResourcesDirectory C:\horizon_integration_data; `
    Remove-Item -Path C:\horizon_integration_data -Recurse -Force;