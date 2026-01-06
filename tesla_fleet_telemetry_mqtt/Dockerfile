ARG BUILD_FROM
ARG FLEET_TELEMETRY_VERSION

# Build stage for fleet-telemetry
FROM golang:1.23-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    git \
    ca-certificates \
    tzdata

ARG FLEET_TELEMETRY_VERSION
ARG TARGETARCH

WORKDIR /build

# Clone and build fleet-telemetry
RUN git clone --depth 1 --branch ${FLEET_TELEMETRY_VERSION} \
    https://github.com/teslamotors/fleet-telemetry.git .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} \
    go build -a -installsuffix cgo \
    -ldflags="-w -s" \
    -o fleet-telemetry \
    ./cmd/fleet-telemetry

# Runtime stage
FROM $BUILD_FROM

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    jq \
    ca-certificates \
    tzdata

# Copy the binary from builder
COPY --from=builder /build/fleet-telemetry /usr/local/bin/fleet-telemetry

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
