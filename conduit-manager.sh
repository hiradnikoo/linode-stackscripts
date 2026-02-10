#!/bin/bash
# 
# github: https://github.com/hiradnikoo/linode-stackscripts
# 
# StackScript for Psiphon Conduit Manager
#
# <UDF name="MAX_CLIENTS" Label="Max Clients" default="200" example="Maximum concurrent proxy clients per container (1-1000)" />
# <UDF name="BANDWIDTH" Label="Bandwidth (Mbps)" default="10" example="Bandwidth limit per peer in Mbps (1-40, or -1 for unlimited)" />
# <UDF name="CONTAINER_COUNT" Label="Container Count" default="8" example="Number of containers to run (1-32)" />
# <UDF name="USE_TELEGRAM" Label="Enable Telegram Notifications?" oneof="No,Yes" default="No" />
# <UDF name="TELEGRAM_BOT_TOKEN" Label="Telegram Bot Token" default="" example="123456789:ABC-DEF1234ghIkl-zyx57W2v1u" />
# <UDF name="TELEGRAM_CHAT_ID" Label="Telegram Chat ID" default="" example="Find the value from id inside chat object from https://api.telegram.org/{TELEGRAM_BOT_TOKEN}/getUpdates" />
# <UDF name="TELEGRAM_SERVER_LABEL" Label="Telegram Server Label" default="Conduit Manager"/>

# Log all output to a file for debugging
exec > >(tee -i /var/log/stackscript.log)
exec 2>&1

echo "Starting Psiphon Conduit Manager installation..."

# Update system
echo "Updating system packages..."
DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confold"
apt-get install -y curl

# Download the install script
echo "Downloading conduit.sh..."
curl -sL https://raw.githubusercontent.com/SamNet-dev/conduit-manager/main/conduit.sh -o conduit.sh

# Patch the script to remove interactive prompts
echo "Patching conduit.sh for non-interactive installation..."

# Ensure we have the script content before patching
if [ ! -s conduit.sh ]; then
    echo "Error: Failed to download conduit.sh"
    exit 1
fi

# 1. Disable prompt_settings call
sed -i 's/^\s*prompt_settings\s*$/true # prompt_settings # Disabled by StackScript/' conduit.sh

# 2. Disable final "Open management menu now?" prompt
# Look for: read -p "Open management menu now? [Y/n] " open_menu
sed -i 's/read -p "Open management menu now? \[Y\/n\] " open_menu/open_menu="n" # read -p "Disabled prompt" open_menu/' conduit.sh

# 3. Disable opening the menu at the end
# The original script has this inside an 'if' block. Commenting it out leaves the 'if' block empty,
# which causes a syntax error (unexpected token 'fi'). We replace it with 'true' to keep the block valid.
sed -i 's/"$INSTALL_DIR\/conduit" menu/true # Menu disabled by StackScript/' conduit.sh

# Set environment variables for the script to pick up intended settings
# The script uses these variables if they are set, bypassing prompts if prompts are disabled.
# However, the script's `prompt_settings` function RE-SETS them if it runs.
# Since we disabled `prompt_settings`, we must ensure variables are set correctly.

export MAX_CLIENTS="${MAX_CLIENTS:-200}"
export BANDWIDTH="${BANDWIDTH:-5}"
export CONTAINER_COUNT="${CONTAINER_COUNT:-1}"
export TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
export TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
export TELEGRAM_SERVER_LABEL="${TELEGRAM_SERVER_LABEL:-}"
export USE_TELEGRAM="${USE_TELEGRAM:-}"

echo "Configuration:"
echo "  MAX_CLIENTS: $MAX_CLIENTS"
echo "  BANDWIDTH: $BANDWIDTH"
echo "  CONTAINER_COUNT: $CONTAINER_COUNT"

# Run the installation
export INSTALL_DIR="/opt/conduit"
echo "Executing patched conduit.sh..."
bash conduit.sh --reinstall

echo "Installation complete. Forcing configuration update..."

TELEGRAM_ENABLED_VAL="false"
if [ "$USE_TELEGRAM" == "Yes" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    TELEGRAM_ENABLED_VAL="true"
    echo "  Telegram: Enabled"
else
    echo "  Telegram: Disabled"
fi

mkdir -p /opt/conduit
cat > /opt/conduit/settings.conf <<EOF
MAX_CLIENTS=${MAX_CLIENTS:-200}
BANDWIDTH=${BANDWIDTH:-5}
CONTAINER_COUNT=${CONTAINER_COUNT:-1}
DATA_CAP_GB=0
DATA_CAP_IFACE=
DATA_CAP_BASELINE_RX=0
DATA_CAP_BASELINE_TX=0
DATA_CAP_PRIOR_USAGE=0
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"
TELEGRAM_INTERVAL=6
TELEGRAM_ENABLED=${TELEGRAM_ENABLED_VAL}
TELEGRAM_ALERTS_ENABLED=true
TELEGRAM_DAILY_SUMMARY=true
TELEGRAM_WEEKLY_SUMMARY=true
TELEGRAM_SERVER_LABEL="${TELEGRAM_SERVER_LABEL}"
TELEGRAM_START_HOUR=0
EOF

chmod 600 /opt/conduit/settings.conf
echo "Configuration saved to /opt/conduit/settings.conf"

# Restart services to pick up changes
if command -v systemctl &>/dev/null; then
    echo "Restarting services..."
    systemctl restart conduit || true
    if [ "$TELEGRAM_ENABLED_VAL" == "true" ]; then
        systemctl restart conduit 2>/dev/null || true
    fi
fi

echo "Installation complete!"
echo "You can manage the conduit by running 'conduit' command as root."
