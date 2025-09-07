#!/usr/bin/env bash

# Check if pwsh exists
if ! command -v pwsh &> /dev/null; then
  echo "PowerShell not found. Installing..."

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Install on Ubuntu/Debian
    sudo apt update
    sudo apt install -y wget apt-transport-https software-properties-common
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt update
    sudo apt install -y powershell
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS install via Homebrew
    if ! command -v brew &> /dev/null; then
      echo "Homebrew not found. Please install Homebrew first."
      exit 1
    fi
    brew install --cask powershell
  else
    echo "Unsupported OS for auto-install."
    exit 1
  fi
fi

# Now call the PowerShell script
pwsh ./setup-odoo.ps1 "$@"
