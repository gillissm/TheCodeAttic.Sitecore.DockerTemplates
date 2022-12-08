# escape=`

ARG PARENT_IMAGE
ARG TOOLS_IMAGE
ARG SMS_IMAGE
ARG SPE_IMAGE

FROM ${TOOLS_IMAGE} as tools
FROM ${SMS_IMAGE} AS management_services
FROM ${SPE_IMAGE} AS spe
FROM ${PARENT_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR C:\inetpub\wwwroot

# Copy developer tools and entrypoint
COPY --from=tools C:\tools C:\tools

# Copy the Sitecore Management Services Module
COPY --from=management_services C:\module\cm\content C:\inetpub\wwwroot

# Add SPE module
COPY --from=spe \module\cm\content C:\inetpub\wwwroot