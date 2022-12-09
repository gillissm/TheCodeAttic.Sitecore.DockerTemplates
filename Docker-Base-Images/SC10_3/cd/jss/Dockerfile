# escape=`

# This layers on a Headless Rendering Service Assets onto a CM image

ARG PARENT_IMAGE
ARG JSS_IMAGE

FROM ${JSS_IMAGE} AS jss
FROM ${PARENT_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR C:\inetpub\wwwroot

# Copy and init the JSS Module
COPY --from=jss C:\module\cd\content C:\inetpub\wwwroot
COPY --from=jss C:\module\tools C:\module\tools

RUN C:\module\tools\Initialize-Content.ps1 -TargetPath C:\inetpub\wwwroot; `
  Remove-Item -Path C:\module -Recurse -Force;