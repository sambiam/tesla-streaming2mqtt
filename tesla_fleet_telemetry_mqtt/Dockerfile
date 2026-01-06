ARG BUILD_FROM
ARG FLEET_TELEMETRY_VERSION

# Use Tesla's official pre-built image instead of building from source
FROM tesla/fleet-telemetry:${FLEET_TELEMETRY_VERSION} AS tesla-binary

# Runtime stage
FROM $BUILD_FROM

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    jq \
    ca-certificates \
    tzdata

# Copy the pre-built binary from Tesla's official image
COPY --from=tesla-binary /fleet-telemetry /usr/local/bin/fleet-telemetry

# Make it executable
RUN chmod +x /usr/local/bin/fleet-telemetry

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set working directory
WORKDIR /data

# Labels
LABEL \
    io.hass.name="Tesla Fleet Telemetry MQTT" \
    io.hass.description="Tesla Fleet Telemetry server with MQTT integration" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.arch="${BUILD_ARCH}"

# Start the add-on
CMD [ "/run.sh" ]
