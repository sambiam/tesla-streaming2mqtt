# Tesla Fleet Telemetry MQTT Add-on

[![Release][release-shield]][release-url]
[![License][license-shield]][license-url]

Home Assistant add-on for Tesla Fleet Telemetry with MQTT integration.

## About

This add-on runs Tesla's official Fleet Telemetry server and publishes real-time vehicle data to your local MQTT broker. Get live streaming telemetry from your Tesla directly into Home Assistant.

## Features

- **Real-time streaming** - Direct telemetry from Tesla (not polling)
- **MQTT integration** - Publishes to Home Assistant's Mosquitto broker
- **Secure** - TLS/SSL encryption for Tesla communications
- **Multi-architecture** - Supports amd64, aarch64, and armv7
- **Easy configuration** - All settings via Home Assistant UI

## Quick Start

### Prerequisites

1. **Mosquitto broker** add-on installed and running
2. **Valid TLS certificate** (Let's Encrypt add-on recommended)
3. **Tesla Developer account** with Fleet API configured
4. **Port 443** accessible from the internet

### Installation

1. Copy `tesla_fleet_telemetry_mqtt` folder to `/addons/`
2. Go to **Settings** → **Add-ons** → **Add-on Store**
3. Click ⋮ → **Check for updates**
4. Install **Tesla Fleet Telemetry MQTT** from **Local add-ons**

### Basic Configuration

```yaml
listen_host: "0.0.0.0"
listen_port: 443
tls_cert_path: "/ssl/fullchain.pem"
tls_key_path: "/ssl/privkey.pem"
mqtt_broker: "core-mosquitto:1883"
mqtt_topic_base: "telemetry"
```

### Testing

Monitor MQTT topics to see live data:

```bash
mosquitto_sub -h core-mosquitto -t 'telemetry/#' -v
```

## MQTT Topics

Data is published to topics like:

- `telemetry/<VIN>/v/Location` - GPS coordinates
- `telemetry/<VIN>/v/VehicleSpeed` - Current speed
- `telemetry/<VIN>/v/BatteryLevel` - Battery percentage
- `telemetry/<VIN>/v/Soc` - State of charge
- `telemetry/<VIN>/errors/*` - Vehicle errors
- `telemetry/<VIN>/alerts/*` - Vehicle alerts

## Documentation

For detailed setup instructions, configuration options, and troubleshooting:

- **[Full Documentation](DOCS.md)**
- [Tesla Fleet Telemetry GitHub](https://github.com/teslamotors/fleet-telemetry)
- [Tesla Developer Portal](https://developer.tesla.com)

## Configuration Reference

| Option | Default | Description |
|--------|---------|-------------|
| `listen_host` | `0.0.0.0` | Interface to listen on |
| `listen_port` | `443` | Port for Tesla connections |
| `tls_cert_path` | `/ssl/fullchain.pem` | TLS certificate path |
| `tls_key_path` | `/ssl/privkey.pem` | TLS private key path |
| `mqtt_broker` | `core-mosquitto:1883` | MQTT broker address |
| `mqtt_client_id` | `fleet-telemetry-ha` | MQTT client ID |
| `mqtt_username` | - | MQTT username (optional) |
| `mqtt_password` | - | MQTT password (optional) |
| `mqtt_topic_base` | `telemetry` | Base topic for messages |
| `mqtt_qos` | `0` | MQTT Quality of Service |
| `mqtt_retained` | `false` | Retain MQTT messages |
| `extra_fleet_config` | `""` | Additional config (JSON string) |

## Troubleshooting

### No data received?

1. Verify Tesla Fleet API is configured with your public URL
2. Ensure port 443 is forwarded to Home Assistant
3. Check that vehicle is awake and online
4. Review add-on logs for connection errors

### TLS certificate errors?

1. Ensure Let's Encrypt add-on is running
2. Verify certificate paths are correct
3. Check certificate hasn't expired
4. Restart add-on after certificate renewal

### MQTT not working?

1. Verify Mosquitto broker is running
2. Check MQTT credentials if authentication enabled
3. Test MQTT with `mosquitto_pub` and `mosquitto_sub`
4. Review Mosquitto broker logs

See [DOCS.md](DOCS.md) for detailed troubleshooting.

## Support

- [Home Assistant Community Forums](https://community.home-assistant.io)
- [Tesla Fleet Telemetry GitHub](https://github.com/teslamotors/fleet-telemetry)
- [Home Assistant Add-on Documentation](https://developers.home-assistant.io/docs/add-ons)

## License

This add-on is licensed under the Apache License 2.0.

Tesla Fleet Telemetry is developed by Tesla and licensed under Apache 2.0.

## Disclaimer

This is an unofficial add-on. It uses Tesla's official Fleet Telemetry server but is not affiliated with, endorsed by, or supported by Tesla, Inc.

---

[release-shield]: https://img.shields.io/badge/version-1.0.0-blue.svg
[release-url]: https://github.com/yourusername/tesla-fleet-telemetry-mqtt
[license-shield]: https://img.shields.io/badge/license-Apache%202.0-blue.svg
[license-url]: LICENSE
