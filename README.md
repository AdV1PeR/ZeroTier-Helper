# ZeroTier Helper (`zt`)

A small, dependency-free wrapper around `zerotier-cli` for the commands you
actually type: join, leave, status, get the assigned IP, restart the service.
No Python, no Node, just Bash.

ZeroTier itself is powerful but its CLI is verbose. `zt` remembers your default
network, validates network IDs and fails with a clear message instead of a
cryptic one.

## Features

- **Default network** — set it once, then `zt join`, `zt status`, `zt ip` work without arguments
- **Input validation** — network IDs must be 16 hex characters
- **Clear errors and exit codes** — `0` success, `1` failure, `2` usage error
- **IP lookup that survives spaces** in network names and multiple addresses
- **Sudo-aware** — uses `sudo` when needed, calls `zerotier-cli` directly as root
- **Service restart** — `systemctl` or `service` fallback
- **Passthrough** — `zt raw ...` for anything not wrapped
- **Config with 600 permissions**, no secrets in the script
- `shellcheck`-clean, CI checks every push

## Requirements

- Linux (systemd or SysV init for `zt restart`)
- [ZeroTier One](https://www.zerotier.com/download/) installed, `zerotier-cli` in `PATH`
- Bash 4.0+
- `sudo` if you are not root

## Installation

```bash
git clone https://github.com/AdV1PeR/ZeroTier-Helper.git
cd ZeroTier-Helper
chmod +x zt.sh
sudo install -m 755 zt.sh /usr/local/bin/zt
```

Check:

```bash
zt version
zt help
```

## Configuration

Set the default network once:

```bash
zt default 8056c2e21c000001
```

It is written to `~/.config/zt/config`:

```bash
ZT_DEFAULT_NETWORK="8056c2e21c000001"
```

Override the path with `ZT_CONFIG=/path/to/config`. Environment variables take
precedence over the file:

| Variable | Meaning |
|---|---|
| `ZT_DEFAULT_NETWORK` | default network ID |
| `ZT_CONFIG` | path to config file |
| `ZT_SUDO` | sudo command, default `sudo`; set to empty to disable |

## Usage

```bash
zt join 8056c2e21c000001   # join a specific network
zt default 8056c2e21c000001
zt join                    # join the default network
zt status                  # status of the default network
zt ip                      # assigned IP(s) in the default network
zt leave                   # leave the default network
zt restart                 # restart zerotier-one
```

| Command | Description |
|---|---|
| `zt join [id]` | join a network (default: configured) |
| `zt leave [id]` | leave a network |
| `zt status [id]` | show the network line from `listnetworks` |
| `zt ip [id]` | show assigned IPv4/IPv6 addresses |
| `zt default [id]` | show or set the default network |
| `zt restart` | restart the `zerotier-one` service |
| `zt info` | node information |
| `zt listnetworks` | all networks |
| `zt listpeers`, `zt peers` | peers |
| `zt listmoons` | moons |
| `zt dump` | debug output |
| `zt raw <args...>` | pass arguments directly to `zerotier-cli` |
| `zt version` | version |
| `zt help` | help |

### Passthrough examples

```bash
zt raw get 8056c2e21c000001 ipAssignments
zt raw set 8056c2e21c000001 allowManaged=0
```

## How sudo works

Every `zerotier-cli` call needs access to the local ZeroTier auth token, which is
root-only on most systems. So `zt` calls `sudo zerotier-cli` by default.

- running as root → calls `zerotier-cli` directly
- `ZT_SUDO="" zt info` → no sudo at all (useful in containers or with a custom setup)
- `ZT_SUDO="doas"` → use another privilege tool

## Tests

Function tests use a mock `zerotier-cli`, so no real ZeroTier installation is
needed:

```bash
bash tests/test.sh
```

They cover ID validation, the default network, config permissions, `status`,
`ip` parsing (including names with spaces and multiple addresses), `raw`
passthrough and exit codes. CI runs both tests and `shellcheck`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `zerotier-cli не найден` | install ZeroTier One, check `command -v zerotier-cli` |
| `Неверный Network ID` | network IDs are 16 hex characters, e.g. `8056c2e21c000001` |
| `Network ... is not joined` | check the ID, or join it first |
| `No assigned IP` | the network is joined but has not issued a lease yet; check authorization in ZeroTier Central |
| `Permission denied` | run with sudo, or configure `ZT_SUDO` |
| `zt restart` fails | check `systemctl status zerotier-one` |

## Uninstall

```bash
sudo rm /usr/local/bin/zt
rm -f ~/.config/zt/config
```

## Security notes

- The script does not store tokens or network secrets; a network ID is not a secret
- The config file is created with `0600` and its directory with `0700`
- `zt raw` passes arguments as separate argv entries (no `eval`, no shell injection)
- The script only calls `zerotier-cli`, `sudo`/`doas`, `systemctl`/`service`

## License

MIT. ZeroTier is a registered trademark of ZeroTier, Inc.
This project is not affiliated with ZeroTier, Inc.
