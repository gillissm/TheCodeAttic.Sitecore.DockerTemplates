# escape=`

ARG PARENT_IMAGE
ARG SPS_IMAGE

FROM ${SPS_IMAGE} AS publishing_services
FROM ${PARENT_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR C:\inetpub\wwwroot

# Copy publishing service module
COPY --from=publishing_services C:\module\cm\content C:\inetpub\wwwroot
