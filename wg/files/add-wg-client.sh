#!/usr/bin/env bash
# Usage: ./add-wg-client.sh --ip <IP> [--config <FILE>] [--name <NAME>] [--dns <DNS>] [--endpoint <ENDPOINT>] [--allowedips <CIDR>]

set -e

# Default variables
CONFIG_FILE="/etc/wireguard/wg0.conf"
CLIENT_NAME=""
CLIENT_IP=""
DNS="1.1.1.1"
ENDPOINT=""
CLIENT_ALLOWED_IPS=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --config) CONFIG_FILE="$2"; shift ;;
        --name) CLIENT_NAME="$2"; shift ;;
        --ip) CLIENT_IP="$2"; shift ;;
        --dns) DNS="$2"; shift ;;
        --endpoint) ENDPOINT="$2"; shift ;;
        --allowedips) CLIENT_ALLOWED_IPS="$2"; shift ;;
        *) echo "[Error] Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# --- Validation & Prerequisites ---

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "[Error] This script must be run as root." >&2
    exit 1
fi

# Check for required tools
for cmd in wg qrencode grep systemctl cut xargs; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "[Error] Required command '$cmd' could not be found. Please install it." >&2
        exit 1
    fi
done

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[Error] WireGuard config file not found at $CONFIG_FILE" >&2
    exit 1
fi

# Ensure IP was provided
if [ -z "$CLIENT_IP" ]; then
    echo "[Error] Client IP must be specified using --ip <IP>" >&2
    exit 1
fi

# Clean up client IP (strip CIDR if user provided one) to ensure strict /32 application
BARE_CLIENT_IP="${CLIENT_IP%/*}"

# Prompt for name if not provided
if [ -z "$CLIENT_NAME" ]; then
    read -p "Enter a name for the new client: " CLIENT_NAME
    if [ -z "$CLIENT_NAME" ]; then
        echo "[Error] Client name cannot be empty." >&2
        exit 1
    fi
fi

# Check if client name already exists in the config
if grep -q "# Client $CLIENT_NAME$" "$CONFIG_FILE"; then
    echo "[Error] A client with the name '$CLIENT_NAME' already exists in $CONFIG_FILE" >&2
    exit 1
fi

# --- Extracting Server Details ---

# Extract Server Private Key to generate Server Public Key
SERVER_PRIV_KEY=$(grep -m 1 -i '^PrivateKey' "$CONFIG_FILE" | cut -d '=' -f 2- | xargs)
if [ -z "$SERVER_PRIV_KEY" ]; then
    echo "[Error] Could not find 'PrivateKey' in $CONFIG_FILE" >&2
    exit 1
fi
SERVER_PUB_KEY=$(echo "$SERVER_PRIV_KEY" | wg pubkey)

# Extract Server IP and strip its CIDR mask
SERVER_IP_RAW=$(grep -m 1 -i '^Address' "$CONFIG_FILE" | cut -d '=' -f 2- | xargs)
if [ -z "$SERVER_IP_RAW" ]; then
    echo "[Error] Could not find server 'Address' in $CONFIG_FILE" >&2
    exit 1
fi
BARE_SERVER_IP="${SERVER_IP_RAW%/*}"

# Determine Client's AllowedIPs (Default to Server IP /32 if not specified)
if [ -z "$CLIENT_ALLOWED_IPS" ]; then
    CLIENT_ALLOWED_IPS="$BARE_SERVER_IP/32"
fi

# Extract or validate Endpoint
if [ -z "$ENDPOINT" ]; then
    # Look for '# Endpoint = xxx' in the server config
    ENDPOINT=$(grep -m 1 -i '^# Endpoint' "$CONFIG_FILE" | cut -d '=' -f 2- | xargs)
    if [ -z "$ENDPOINT" ]; then
        echo "[Error] Endpoint not provided via --endpoint and no '# Endpoint = ' comment found in $CONFIG_FILE" >&2
        exit 1
    fi
fi

# --- Key Generation ---

CLIENT_PRIV_KEY=$(wg genkey)
CLIENT_PUB_KEY=$(echo "$CLIENT_PRIV_KEY" | wg pubkey)
CLIENT_PSK=$(wg genpsk)

# --- Backup and Modification ---

# Create backup
BACKUP_FILE="${CONFIG_FILE}.bak.$(date +%F_%T)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
chmod 600 "$BACKUP_FILE"
echo "[Info] Created backup of config at $BACKUP_FILE"

# Append to Server Config
cat <<EOF >> "$CONFIG_FILE"

# Client $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUB_KEY
PresharedKey = $CLIENT_PSK
AllowedIPs = $BARE_CLIENT_IP/32
EOF

echo "[Info] Successfully appended new peer to $CONFIG_FILE"

# --- Client Configuration Generation ---

CLIENT_CONF=$(cat <<EOF
[Interface]
PrivateKey = $CLIENT_PRIV_KEY
Address = $BARE_CLIENT_IP/32
DNS = $DNS

[Peer]
PublicKey = $SERVER_PUB_KEY
PresharedKey = $CLIENT_PSK
AllowedIPs = $CLIENT_ALLOWED_IPS
Endpoint = $ENDPOINT
EOF
)

# --- Display Results ---

echo -e "\n=============================================="
echo -e "         CLIENT CONFIGURATION DETAILS         "
echo -e "==============================================\n"

# Display text
echo "$CLIENT_CONF"

echo -e "\n=============================================="
echo -e "                 QR CODE                      "
echo -e "==============================================\n"

# Display QR code in terminal
echo "$CLIENT_CONF" | qrencode -t ansiutf8

echo -e "\n[Success] Client '$CLIENT_NAME' has been generated."

# --- Service Restart Prompt ---

echo ""
read -r -p "Do you want to restart the wg-quick@wg0 service to apply changes? [Y/n] " response
if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
    echo "[Info] Skipping service restart. The new client will not be able to connect until the service is restarted or config reloaded."
else
    INTERFACE=$(basename "${CONFIG_FILE%.conf}")
    echo "[Info] Restarting interface ${INTERFACE}..."
    #systemctl restart wg-quick@wg0
    wg syncconf ${INTERFACE} <(wg-quick strip ${INTERFACE})
    echo "[Success] WireGuard service restarted successfully."
fi
