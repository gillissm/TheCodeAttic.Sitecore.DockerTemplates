# escape=`

# This layers on a Headless Rendering Service Assets onto a CM image

ARG PARENT_IMAGE
ARG PUBLISHING_SERVICES_IMAGE

FROM ${PUBLISHING_SERVICES_IMAGE} AS publishing_services
FROM ${PARENT_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR C:\inetpub\wwwroot

# Copy and init the Sitecore Publishing Services Module
COPY --from=publishing_services C:\module\cd\content C:\inetpub\wwwroot

RUN Remove-Item -Path C:\inetpub\wwwroot\App_Config\Modules\PublishingService\Sitecore.Publishing.Service.SingleLinkDatabase.config -Force; 
