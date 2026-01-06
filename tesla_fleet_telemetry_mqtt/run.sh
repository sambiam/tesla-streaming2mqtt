#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting Tesla Fleet Telemetry MQTT add-on..."

#############
# Read configuration from add-on options
#############
LISTEN_HOST=$(bashio::config 'listen_host')
LISTEN_PORT=$(bashio::config 'listen_port')
TLS_CERT_PATH=$(bashio::config 'tls_cert_path')
TLS_KEY_PATH=$(bashio::config 'tls_key_path')

MQTT_BROKER=$(bashio::config 'mqtt_broker')
MQTT_CLIENT_ID=$(bashio::config 'mqtt_client_id')
MQTT_USERNAME=$(bashio::config 'mqtt_username')
MQTT_PASSWORD=$(bashio::config 'mqtt_password')
MQTT_TOPIC_BASE=$(bashio::config 'mqtt_topic_base')
MQTT_QOS=$(bashio::config 'mqtt_qos')
MQTT_RETAINED=$(bashio::config 'mqtt_retained')

#############
# Validation
#############
bashio::log.info "Validating configuration..."

# Validate MQTT broker
if [ -z "$MQTT_BROKER" ]; then
    bashio::log.fatal "MQTT broker is not configured!"
    bashio::exit.nok "Please configure mqtt_broker in add-on options"
fi

# Validate TLS certificate files exist
if [ ! -f "$TLS_CERT_PATH" ]; then
    bashio::log.fatal "TLS certificate not found at: ${TLS_CERT_PATH}"
    bashio::exit.nok "Please ensure TLS certificate exists at configured path"
fi

if [ ! -f "$TLS_KEY_PATH" ]; then
    bashio::log.fatal "TLS private key not found at: ${TLS_KEY_PATH}"
    bashio::exit.nok "Please ensure TLS private key exists at configured path"
fi

bashio::log.info "TLS certificate found: ${TLS_CERT_PATH}"
bashio::log.info "TLS private key found: ${TLS_KEY_PATH}"

#############
# Generate fleet-telemetry configuration
#############
bashio::log.info "Generating fleet-telemetry configuration..."

CONFIG_FILE="/data/fleet-telemetry.json"

# Start with base configuration
cat > "$CONFIG_FILE" << EOF
{
  "host": "${LISTEN_HOST}",
  "port": ${LISTEN_PORT},
  "tls": {
    "server_cert": "${TLS_CERT_PATH}",
    "server_key": "${TLS_KEY_PATH}"
  },
  "mqtt": {
    "broker": "${MQTT_BROKER}",
    "client_id": "${MQTT_CLIENT_ID}",
    "topic_base": "${MQTT_TOPIC_BASE}",
    "qos": ${MQTT_QOS},
    "retained": ${MQTT_RETAINED}
EOF

# Add MQTT username if configured
if [ -n "$MQTT_USERNAME" ]; then
    cat >> "$CONFIG_FILE" << EOF
,
    "username": "${MQTT_USERNAME}"
EOF
fi

# Add MQTT password if configured (never log this!)
if [ -n "$MQTT_PASSWORD" ]; then
    cat >> "$CONFIG_FILE" << EOF
,
    "password": "${MQTT_PASSWORD}"
EOF
fi

# Close MQTT section
cat >> "$CONFIG_FILE" << EOF

  }
}
EOF

# Merge extra_fleet_config if provided
if bashio::config.has_value 'extra_fleet_config'; then
    EXTRA_CONFIG=$(bashio::config 'extra_fleet_config')

    # Only merge if not empty
    if [ -n "$EXTRA_CONFIG" ]; then
        bashio::log.info "Merging extra_fleet_config..."

        # Validate JSON format
        if ! echo "$EXTRA_CONFIG" | jq empty 2>/dev/null; then
            bashio::log.warning "extra_fleet_config is not valid JSON, skipping merge"
        else
            # Merge configurations using jq
            MERGED_CONFIG=$(jq -s '.[0] * .[1]' "$CONFIG_FILE" <(echo "$EXTRA_CONFIG"))

            # Write merged config back
            echo "$MERGED_CONFIG" > "$CONFIG_FILE"

            bashio::log.info "Extra configuration merged successfully"
        fi
    fi
fi

# Validate the generated JSON
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
    bashio::log.fatal "Generated configuration is not valid JSON!"
    bashio::exit.nok "Configuration generation failed"
fi

bashio::log.info "Configuration generated successfully"

# Log configuration (redact sensitive fields)
bashio::log.info "Fleet Telemetry Configuration:"
jq 'walk(if type == "object" then with_entries(if .key | test("password|key|secret"; "i") then .value = "***REDACTED***" else . end) else . end)' "$CONFIG_FILE" | while read -r line; do
    bashio::log.info "  ${line}"
done

#############
# Start fleet-telemetry server
#############
bashio::log.info "Starting fleet-telemetry server on ${LISTEN_HOST}:${LISTEN_PORT}..."
bashio::log.info "MQTT broker: ${MQTT_BROKER}"
bashio::log.info "MQTT topic base: ${MQTT_TOPIC_BASE}"

# Check if binary exists and is executable
if [ ! -x /usr/local/bin/fleet-telemetry ]; then
    bashio::log.fatal "fleet-telemetry binary not found or not executable!"
    bashio::exit.nok "Installation error"
fi

# Execute fleet-telemetry
# Note: Using exec to replace the shell process so signals are handled properly
exec /usr/local/bin/fleet-telemetry -config "$CONFIG_FILE"
