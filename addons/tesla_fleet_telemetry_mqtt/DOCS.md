# Tesla Fleet Telemetry MQTT Add-on Documentation

## Overview

This Home Assistant add-on runs Tesla's Fleet Telemetry server, which receives real-time streaming telemetry data directly from your Tesla vehicle(s) and publishes it to your local MQTT broker.

**Key Features:**
- Real-time streaming telemetry (not polling)
- Direct MQTT integration with Home Assistant's Mosquitto broker
- TLS/SSL encryption for Tesla communications
- Multi-architecture support (amd64, aarch64, armv7)
- Fully configurable via Home Assistant UI

## Prerequisites

### 1. Mosquitto MQTT Broker

The Mosquitto broker add-on must be installed and running:

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Search for "Mosquitto broker"
3. Install and start it
4. Note: The default host is `core-mosquitto:1883`

### 2. TLS/SSL Certificate

Tesla requires a valid TLS certificate for Fleet Telemetry. You have two options:

#### Option A: Let's Encrypt Add-on (Recommended)

1. Install the **Let's Encrypt** add-on from the official add-on store
2. Configure it with your domain name
3. Certificates will be available at:
   - Certificate: `/ssl/fullchain.pem`
   - Private Key: `/ssl/privkey.pem`

#### Option B: Manual Certificate

1. Obtain a certificate from any CA
2. Copy files to Home Assistant's `/ssl/` directory (via Samba or SSH)
3. Configure paths in add-on options

### 3. Tesla Developer Account & Fleet API Setup

You must register your Fleet Telemetry server with Tesla:

1. Create a Tesla Developer account at https://developer.tesla.com
2. Create a new application
3. Configure Fleet Telemetry settings:
   - **Server URL**: `https://your-domain.com:443` (your public URL)
   - **CA Certificate**: Upload your certificate's CA
4. Generate and note your application credentials
5. Configure your vehicle to send telemetry to your server

**Important**: Your Home Assistant instance must be accessible from the internet on port 443 (or your configured port) for Tesla to reach it.

## Installation

### Installing as a Local Add-on

1. **Copy add-on files:**
   - Using Samba: Copy the `tesla_fleet_telemetry_mqtt` folder to `/addons/`
   - Using SSH: Copy or git clone to `/addons/`

2. **Reload add-on store:**
   - Go to **Settings** → **Add-ons** → **Add-on Store**
   - Click the three-dot menu (⋮) → **Check for updates**

3. **Install the add-on:**
   - Scroll down to the **Local add-ons** section
   - Find **Tesla Fleet Telemetry MQTT**
   - Click it and then click **Install**

## Configuration

### Basic Configuration

```yaml
listen_host: "0.0.0.0"
listen_port: 443
tls_cert_path: "/ssl/fullchain.pem"
tls_key_path: "/ssl/privkey.pem"
mqtt_broker: "core-mosquitto:1883"
mqtt_client_id: "fleet-telemetry-ha"
mqtt_username: ""
mqtt_password: ""
mqtt_topic_base: "telemetry"
mqtt_qos: 0
mqtt_retained: false
extra_fleet_config: {}
```

### Configuration Options

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `listen_host` | Yes | `0.0.0.0` | Interface to listen on (use `0.0.0.0` for all) |
| `listen_port` | Yes | `443` | Port for Tesla to connect to (Tesla requires 443) |
| `tls_cert_path` | Yes | `/ssl/fullchain.pem` | Path to TLS certificate |
| `tls_key_path` | Yes | `/ssl/privkey.pem` | Path to TLS private key |
| `mqtt_broker` | Yes | `core-mosquitto:1883` | MQTT broker address |
| `mqtt_client_id` | Yes | `fleet-telemetry-ha` | MQTT client identifier |
| `mqtt_username` | No | - | MQTT authentication username |
| `mqtt_password` | No | - | MQTT authentication password |
| `mqtt_topic_base` | Yes | `telemetry` | Base topic for all messages |
| `mqtt_qos` | Yes | `0` | MQTT Quality of Service (0, 1, or 2) |
| `mqtt_retained` | Yes | `false` | Whether MQTT messages should be retained |
| `extra_fleet_config` | No | `{}` | Additional fleet-telemetry config (see below) |

### MQTT Authentication

If you've configured authentication on your Mosquitto broker:

```yaml
mqtt_username: "your_mqtt_user"
mqtt_password: "your_mqtt_password"
```

### Advanced Configuration

Use `extra_fleet_config` to add or override any fleet-telemetry configuration fields:

```yaml
extra_fleet_config:
  log_level: "debug"
  reliable_ack_sources:
    - alerts
    - errors
  monitoring:
    prometheus_metrics_port: 9090
```

These fields will be deep-merged into the generated configuration.

## MQTT Topics

Telemetry data is published to topics following this structure:

```
<mqtt_topic_base>/<VIN>/<record_type>/<field_name>
```

### Examples

With default `mqtt_topic_base: "telemetry"` and VIN `5YJ3E1EA1KF000001`:

- `telemetry/5YJ3E1EA1KF000001/v/Location` - Vehicle location data
- `telemetry/5YJ3E1EA1KF000001/v/VehicleSpeed` - Speed
- `telemetry/5YJ3E1EA1KF000001/v/BatteryLevel` - Battery state of charge
- `telemetry/5YJ3E1EA1KF000001/v/Soc` - State of charge percentage
- `telemetry/5YJ3E1EA1KF000001/errors/<error>` - Vehicle errors
- `telemetry/5YJ3E1EA1KF000001/alerts/<alert>` - Vehicle alerts

### Record Types

- `v` - Vehicle telemetry (speed, battery, location, etc.)
- `errors` - Vehicle error messages
- `alerts` - Vehicle alert messages

## Testing & Verification

### 1. Check Add-on Logs

After starting the add-on:

1. Go to **Settings** → **Add-ons** → **Tesla Fleet Telemetry MQTT**
2. Click the **Log** tab
3. Look for:
   ```
   [INFO] Starting fleet-telemetry server on 0.0.0.0:443...
   [INFO] MQTT broker: core-mosquitto:1883
   ```

### 2. Subscribe to MQTT Topics

#### Using Terminal & SSH Add-on

```bash
mosquitto_sub -h core-mosquitto -p 1883 -t 'telemetry/#' -v
```

With authentication:
```bash
mosquitto_sub -h core-mosquitto -p 1883 -u your_user -P your_password -t 'telemetry/#' -v
```

#### Using MQTT Explorer (Recommended)

1. Install an MQTT client like MQTT Explorer on your desktop
2. Connect to your Home Assistant IP on port 1883
3. Browse the `telemetry/` topic tree

### 3. Trigger Tesla Data

To verify the connection:

1. Ensure your vehicle is awake
2. Drive the vehicle or interact with it
3. Watch for messages in your MQTT subscription
4. First messages may take a few minutes to appear

### Quick Test Command

Run this from SSH/Terminal add-on to see live data:

```bash
mosquitto_sub -h core-mosquitto -t 'telemetry/#' -v | grep --line-buffered "telemetry/"
```

Press `Ctrl+C` to stop.

## Troubleshooting

### Add-on Won't Start

**Check logs for specific errors:**

1. **"TLS certificate not found"**
   - Verify Let's Encrypt add-on is running
   - Check certificate paths in configuration
   - Ensure `/ssl/` directory contains your certificates

2. **"MQTT broker is not configured"**
   - Ensure `mqtt_broker` is set in options
   - Default should be `core-mosquitto:1883`

3. **"fleet-telemetry binary not found"**
   - The add-on build failed
   - Try rebuilding: **Settings** → **System** → **Repairs**

### No Data Received

1. **Verify Tesla configuration:**
   - Check your Fleet API settings at developer.tesla.com
   - Ensure server URL points to your public address
   - Verify port 443 is forwarded to Home Assistant

2. **Check vehicle configuration:**
   - Ensure telemetry is enabled for your vehicle
   - Vehicle must be awake and online
   - May take up to 5-10 minutes for first data

3. **Test MQTT connectivity:**
   ```bash
   mosquitto_pub -h core-mosquitto -t 'test/topic' -m 'hello'
   mosquitto_sub -h core-mosquitto -t 'test/#' -v
   ```

4. **Check firewall/router:**
   - Port 443 must be open and forwarded
   - Some ISPs block port 443 for residential connections

### TLS/Certificate Issues

**"certificate signed by unknown authority"**
- Ensure your certificate is from a trusted CA
- Upload the CA certificate to Tesla Developer Portal

**"certificate has expired"**
- Renew your Let's Encrypt certificate
- Check Let's Encrypt add-on logs
- Restart this add-on after renewal

### MQTT Authentication Failures

**"connection refused: not authorized"**
- Verify MQTT username/password in configuration
- Check Mosquitto broker logs
- Ensure user has publish permissions on `telemetry/#`

### Port Conflicts

**"address already in use"**
- Another service is using port 443
- Change `listen_port` to another port (e.g., 8443)
- Update port mapping in add-on configuration
- Update Tesla Fleet API configuration with new port

## Network Configuration

### Port Forwarding

You must forward traffic from the internet to Home Assistant:

1. **Router configuration:**
   - Forward external port 443 → Home Assistant IP:443
   - Use TCP protocol
   - Configure static IP or DHCP reservation for HA

2. **Firewall:**
   - Allow incoming TCP on port 443
   - Some firewalls require explicit rules for Docker containers

### Dynamic DNS

If you don't have a static IP:

1. Use a DDNS service (DuckDNS, No-IP, etc.)
2. Install corresponding Home Assistant add-on
3. Use your DDNS domain in Tesla Fleet API config

## Security Considerations

1. **TLS is required** - Never disable TLS for fleet telemetry
2. **Keep certificates updated** - Expired certs will break the connection
3. **Firewall rules** - Only expose port 443, nothing else
4. **MQTT passwords** - Use strong passwords if enabling MQTT auth
5. **Monitor logs** - Watch for unauthorized connection attempts

## Performance & Resource Usage

**Typical resource usage:**
- CPU: 1-5% (idle), 10-20% (active streaming)
- Memory: 50-150 MB
- Network: Varies by vehicle activity (typically <1 Mbps)
- Disk: Minimal (logs only)

**Scaling:**
- Can handle multiple vehicles simultaneously
- Each vehicle streams independently
- MQTT is lightweight and efficient

## Advanced Topics

### Custom Field Filtering

Not all fields may be useful. To filter in Home Assistant:

1. Use MQTT discovery patterns in automations
2. Create template sensors for specific fields
3. Use Node-RED for complex filtering

### Integration with Home Assistant

This add-on only handles data collection. To create Home Assistant entities:

1. Install a companion custom integration (if available)
2. Manually create MQTT sensors in `configuration.yaml`
3. Use auto-discovery with proper naming conventions

Example manual sensor:

```yaml
mqtt:
  sensor:
    - name: "Tesla Battery Level"
      state_topic: "telemetry/5YJ3E1EA1KF000001/v/BatteryLevel"
      unit_of_measurement: "%"
      device_class: battery
```

### Monitoring

Check add-on health:

```bash
# View running processes
ps aux | grep fleet-telemetry

# Check network connections
netstat -tlnp | grep 443

# Monitor MQTT traffic
mosquitto_sub -h core-mosquitto -t '$SYS/#' -v
```

## Support & Resources

- **Tesla Fleet Telemetry**: https://github.com/teslamotors/fleet-telemetry
- **Tesla Developer Docs**: https://developer.tesla.com
- **Home Assistant Forums**: https://community.home-assistant.io
- **MQTT Docs**: https://www.home-assistant.io/integrations/mqtt/

## Changelog

### Version 1.0.0
- Initial release
- Multi-architecture support
- MQTT integration
- TLS/SSL support
- Configuration validation
