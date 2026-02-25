---
name: homeassistant
description: Control smart home devices and run automations via Home Assistant.
metadata: { "openclaw": { "emoji": "🏠", "requires": { "env": ["HA_URL", "HA_TOKEN"] } } }
---

# Home Assistant Integration

You have access to the user's Home Assistant instance via its REST API.

## Authentication
- `HA_URL`: The base URL of the Home Assistant instance (e.g. `http://192.168.1.100:8123`)
- `HA_TOKEN`: Long-lived access token for authentication

All requests MUST include:
```
Authorization: Bearer $HA_TOKEN
Content-Type: application/json
```

## Available Actions

### Get system status
```bash
curl -s "$HA_URL/api/" \
  -H "Authorization: Bearer $HA_TOKEN"
```

### List all entities (devices/sensors)
```bash
curl -s "$HA_URL/api/states" \
  -H "Authorization: Bearer $HA_TOKEN" | python3 -c "
import sys, json
states = json.load(sys.stdin)
for s in sorted(states, key=lambda x: x['entity_id']):
    print(f\"{s['entity_id']}: {s['state']} ({s['attributes'].get('friendly_name', '')})\")" 
```

### Get state of an entity
```bash
curl -s "$HA_URL/api/states/ENTITY_ID" \
  -H "Authorization: Bearer $HA_TOKEN"
```

### Turn on a device
```bash
curl -s -X POST "$HA_URL/api/services/homeassistant/turn_on" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "ENTITY_ID"}'
```

### Turn off a device
```bash
curl -s -X POST "$HA_URL/api/services/homeassistant/turn_off" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "ENTITY_ID"}'
```

### Toggle a device
```bash
curl -s -X POST "$HA_URL/api/services/homeassistant/toggle" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "ENTITY_ID"}'
```

### Set light brightness/color
```bash
curl -s -X POST "$HA_URL/api/services/light/turn_on" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "light.ENTITY", "brightness": 200, "color_name": "blue"}'
```

### Set climate temperature
```bash
curl -s -X POST "$HA_URL/api/services/climate/set_temperature" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "climate.ENTITY", "temperature": 22}'
```

### Fire an event
```bash
curl -s -X POST "$HA_URL/api/events/EVENT_TYPE" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

### Call any service
```bash
curl -s -X POST "$HA_URL/api/services/DOMAIN/SERVICE" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "ENTITY_ID"}'
```

## Common Entity ID Patterns
- Lights: `light.living_room`, `light.bedroom`
- Switches: `switch.plug_1`, `switch.fan`
- Climate: `climate.thermostat`
- Sensors: `sensor.temperature`, `sensor.humidity`
- Media: `media_player.tv`

## Rules
- Always use `exec` with `curl` to make API calls.
- When listing entities, group by domain (lights, switches, sensors, etc.).
- **Confirm before turning devices on/off** — especially climate and security devices.
- Present sensor data with units and friendly names.
- If the HA instance is unreachable, let the user know to check their URL and network.
