# escape=`

ARG BASE_IMAGE
#ARG SOLUTION_IMAGE

#FROM ${SOLUTION_IMAGE} as sln
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Add copy custom core details, expects a JSON file
#COPY --from=sln \artifacts\solr C:\data\
