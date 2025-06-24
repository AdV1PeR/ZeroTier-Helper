# ZeroTier Helper Script (`zt`)

A simplified CLI wrapper for ZeroTier that streamlines VPN network management. Automates frequent operations and adds quality-of-life improvements for working with ZeroTier networks.

**Important Security Note**: This script uses `sudo` for all operations by design. Please only use this tool on systems where you have appropriate administrative privileges.

## Key Features

- 🚀 Simplified network join/leave commands
- ⚡ Automatic sudo handling for all operations
- 🔑 Preconfigured default network ID
- 🌐 Quick IP address retrieval
- 🔄 One-command service restart
- 📋 Full compatibility with standard zerotier-cli commands
- ✅ Network status monitoring

## Installation

1. Clone repository or download script:
```bash
git clone https://github.com/AdV1PeR/ZeroTier-Helper.git
cd zerotier-helper
```

2. Install system-wide:
```bash
chmod +x zt
sudo mv zt /usr/local/bin/
```

## Usage

### Basic Commands

| Command          | Description                                  | Example                     |
|------------------|------------------------------------------|----------------------------|
| `zt join`        | Join default network            | `zt join`                  |
| `zt leave`       | Leave default network            | `zt leave`                 |
| `zt status`      | Show connection status              | `zt status`                |
| `zt ip`          | Show assigned IP address            | `zt ip`                    |
| `zt restart`     | Restart ZeroTier service            | `zt restart`               |
| `zt join <ID>`   | Join specific network            | `zt join abcd1234`         |
| `zt leave <ID>`  | Leave specific network            | `zt leave xyz7890`         |

### Standard zerotier-cli Commands

All native commands are supported:

```bash
zt info          # Node information
zt listnetworks  # List all networks
zt listpeers     # List all peers
zt peers         # Formatted peer list
zt dump          # Debug information
zt listmoons     # Show connected moons
```

## Usage Examples

1. Join default network:
```bash
zt join
```

2. Check connection status:
```bash
zt status
```

3. Get assigned IP address:
```bash
zt ip
```

4. Join additional network:
```bash
zt join abcd1234xyz
```

5. Restart ZeroTier service:
```bash
zt restart
```

6. Show node information:
```bash
zt info
```

7. List all connected networks:
```bash
zt listnetworks
```

## Security Considerations

1. **Automatic Sudo Usage**: This script automatically uses `sudo` for all ZeroTier operations
2. **Privileged Access**: Requires and uses root-level access to manage ZeroTier
3. **System Modification**: Modifies network configuration and system services
4. **Script Location**: Installs to system-wide `/usr/local/bin` directory

## Requirements

- ZeroTier One installed (https://www.zerotier.com/download/))
- Bash 4.0 or newer
- Sudo privileges for current user
- Systemd-based Linux distribution

## Contribution

Contributions are welcome! Please open an issue or pull request for:
- Bug reports
- Feature requests
- Compatibility improvements
- Documentation updates

## License

Licensed under [MIT License]

ZeroTier is a registered trademark of ZeroTier, Inc. This project is not affiliated with ZeroTier, Inc.
