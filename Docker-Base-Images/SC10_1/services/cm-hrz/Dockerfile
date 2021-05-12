# escape=`

ARG BASE_IMAGE
ARG HRZ_IMAGE

FROM ${HRZ_IMAGE} as hrz
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR C:\inetpub\wwwroot

# Add horizon module
COPY --from=hrz \module\cm\content \inetpub\wwwroot
