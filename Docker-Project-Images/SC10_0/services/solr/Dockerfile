# escape=`

ARG BASE_IMAGE
ARG SOLUTION_IMAGE
ARG SOLR_CORE_NAMES

FROM ${SOLUTION_IMAGE} as sln
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Add SXA module
#COPY --from=sln \artifacts\solr \custom_data

# Set enviroment variable to pass through the solr core names, todo: determine a way to set from the asset image
#ENV coreNames='${SOLR_CORE_NAMES}'
#RUN C:\Add-SolrCores.ps1 -SolrPath C:\solr -SolrSchemaPath C:\custom_data\managed-schema -SolrCoreNames $env:coreNames; `
#    Remove-Item -Path C:\custom_data -Recurse -Force;