# escape=`

ARG PARENT_IMAGE
ARG SPE_IMAGE

FROM ${SPE_IMAGE} AS spe
FROM ${PARENT_IMAGE}


# Copy and init the JSS / Headless Services Module
COPY --from=spe C:\module\db C:\spe_data