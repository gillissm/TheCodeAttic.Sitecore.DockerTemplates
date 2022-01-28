# escape=`

# This layers on a Horizon Assets onto a CM image

ARG PARENT_IMAGE
ARG HRZ_IMAGE

FROM ${HRZ_IMAGE} as hrz
FROM ${PARENT_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR C:\inetpub\wwwroot

# Add horizon module
COPY --from=hrz \module\cm\content \inetpub\wwwroot