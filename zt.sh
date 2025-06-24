#!/bin/bash

# Configuration
DEFAULT_NETWORK=""  # Put here your Network ID
ZT_CMD="sudo zerotier-cli"              # Always use sudo

zt_command() {
    case "$1" in
        join)
            local network_id="${2:-$DEFAULT_NETWORK}"
            echo "Joining network $network_id"
            $ZT_CMD join "$network_id"
            ;;
        leave)
            local network_id="${2:-$DEFAULT_NETWORK}"
            echo "Leaving network $network_id"
            $ZT_CMD leave "$network_id"
            ;;
        status)
            local network_id="${2:-$DEFAULT_NETWORK}"
            $ZT_CMD listnetworks | grep -w "$network_id"
            ;;
        info|listpeers|peers|listnetworks|listmoons|dump)
            $ZT_CMD "$@"
            ;;
        restart)
            echo "Restarting ZeroTier service"
            sudo systemctl restart zerotier-one
            ;;
        ip)
            $ZT_CMD listnetworks | grep -w "$DEFAULT_NETWORK" | awk '{print $9}' | tr -d ','
            ;;
        help|"")
            echo "ZeroTier Helper (sudo wrapper)"
            echo "Usage: zt <command> [network]"
            echo "Commands:"
            echo "  join [id]   - Join network (default: $DEFAULT_NETWORK)"
            echo "  leave [id]  - Leave network"
            echo "  status [id] - Show network status"
            echo "  ip          - Show assigned IP in default network"
            echo "  restart     - Restart ZeroTier service"
            echo "  info, listpeers, peers, listnetworks, listmoons, dump"
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use 'zt help' for usage information"
            return 1
            ;;
    esac
}

zt_command "$@"
