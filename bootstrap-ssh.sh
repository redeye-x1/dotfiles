#!/bin/bash
# bootstrap-ssh.sh
# Retrieves SSH keys from Bitwarden and sets them up

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== SSH Key Setup from Bitwarden ==="
echo ""

# Check for required tools
if ! command -v bw &> /dev/null; then
    echo "Error: Bitwarden CLI not found. Installing..."
    brew install bitwarden-cli
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq not found. Installing..."
    brew install jq
fi

# Check if already logged in
if bw login --check &>/dev/null; then
    echo "✓ Already logged in to Bitwarden"
else
    # Not logged in, ask for server
    echo "Which Bitwarden server do you use?"
    echo "1) US (.com) [default]"
    echo "2) EU (.eu)"
    echo "3) Custom server"
    echo -n "Enter choice [1-3]: "
    read -r server_choice

    BW_SERVER=""
    case "$server_choice" in
        2)
            BW_SERVER="https://vault.bitwarden.eu"
            echo "Setting EU server: $BW_SERVER"
            bw config server "$BW_SERVER"
            ;;
        3)
            echo -n "Enter custom server URL: "
            read -r BW_SERVER
            echo "Setting custom server: $BW_SERVER"
            bw config server "$BW_SERVER"
            ;;
        *)
            echo "Using US server (default)"
            ;;
    esac

    # Login to Bitwarden
    echo "Please enter your Bitwarden credentials:"
    bw login
fi

# Unlock vault
echo "Unlocking Bitwarden vault..."
if ! BW_SESSION=$(bw unlock --raw); then
    echo "Failed to unlock vault"
    exit 1
fi

export BW_SESSION

# Create .ssh directory in dotfiles repo (for stow)
mkdir -p "$DOTFILES_DIR/ssh/.ssh"
chmod 700 "$DOTFILES_DIR/ssh/.ssh"

echo ""
echo "Looking for 'SSH Keys' folder in Bitwarden..."

# Bitwarden folder name for SSH keys
BW_FOLDER="SSH Keys"

# Check if the folder exists
FOLDER_ID=$(bw list folders | jq -r ".[] | select(.name == \"$BW_FOLDER\") | .id")

if [ -z "$FOLDER_ID" ]; then
    echo "⚠ 'SSH Keys' folder not found in Bitwarden."
    echo "Skipping SSH key setup."
    echo ""
    echo "To set up SSH keys:"
    echo "1. Create a folder named 'SSH Keys' in Bitwarden"
    echo "2. Add your SSH keys as Secure Notes in that folder"
    echo "3. Run this script again"
    bw lock
    exit 0
fi

echo "✓ Found 'SSH Keys' folder"
echo ""
echo "Retrieving SSH keys from folder..."
echo ""

# Get all items from the SSH Keys folder
ITEMS=$(bw list items --folderid "$FOLDER_ID" | jq -r '.[] | select(.type == 2) | @json')

# Track if any keys were found
KEYS_FOUND=0

# Function to sanitize item name to valid filename
sanitize_name() {
    local name="$1"
    # Convert to lowercase, replace spaces and special chars with underscores
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//'
}

# Function to ask yes/no question
ask_override() {
    local prompt="$1"
    while true; do
        echo -n "$prompt [y/N] "
        read -r reply </dev/tty
        case "$reply" in
            [Yy]*) return 0 ;;
            [Nn]*|"") return 1 ;;
        esac
    done
}

# Process each item
if [ -z "$ITEMS" ]; then
    echo "⚠ No Secure Notes found in 'SSH Keys' folder"
else
    while IFS= read -r item; do
        # Extract item name and notes
        ITEM_NAME=$(echo "$item" | jq -r '.name')
        ITEM_NOTES=$(echo "$item" | jq -r '.notes // empty')
        
        # Skip if no notes (empty key)
        if [ -z "$ITEM_NOTES" ]; then
            echo "⚠ Skipping '$ITEM_NAME' (empty notes)"
            continue
        fi
        
        # Sanitize name for filename
        SAFE_NAME=$(sanitize_name "$ITEM_NAME")
        
        # Validate sanitized name
        if [ -z "$SAFE_NAME" ]; then
            echo "⚠ Skipping '$ITEM_NAME' (could not sanitize name)"
            continue
        fi
        
        OUTPUT_FILE="$DOTFILES_DIR/ssh/.ssh/id_ed25519_$SAFE_NAME"
        
        # Ensure .ssh directory exists in dotfiles repo
        mkdir -p "$DOTFILES_DIR/ssh/.ssh"
        chmod 700 "$DOTFILES_DIR/ssh/.ssh"
        
        # Check if file already exists
        if [ -f "$OUTPUT_FILE" ]; then
            if ask_override "  '$ITEM_NAME' already exists at $OUTPUT_FILE. Override?"; then
                echo "$ITEM_NOTES" > "$OUTPUT_FILE"
                chmod 600 "$OUTPUT_FILE"
                echo "✓ $ITEM_NAME → $OUTPUT_FILE (overwritten)"
                KEYS_FOUND=1
            else
                echo "⊘ Skipped '$ITEM_NAME'"
            fi
        else
            # Create new key file
            echo "$ITEM_NOTES" > "$OUTPUT_FILE"
            chmod 600 "$OUTPUT_FILE"
            echo "✓ $ITEM_NAME → $OUTPUT_FILE"
            KEYS_FOUND=1
        fi
    done <<< "$ITEMS"
fi

# Lock vault after use for security
bw lock

echo ""
if [ $KEYS_FOUND -eq 1 ]; then
    echo "=== SSH keys setup complete! ==="
    echo ""
    echo "Keys downloaded to: $DOTFILES_DIR/ssh/.ssh/"
    echo "(They will be symlinked to ~/.ssh/ when you run stow)"
else
    echo "=== Warning: No SSH keys were found in Bitwarden ==="
    echo "Please add your SSH keys to Bitwarden first."
    echo "See README.md for instructions."
fi
