#!/bin/bash

# Start Ollama server
echo "Starting Ollama serve..."
sudo ollama serve &

# Wait for a few seconds to ensure Ollama has started
sleep 5

# Install the open-webui package via pip
echo "Installing Open-WebUI via pip..."
sudo pip install open-webui

# Start Open-WebUI
echo "Starting Open-WebUI serve..."
sudo open-webui serve &

echo "This server's IP is: " \ curl ifconfig.me -4

sudo apt install openssh-server
sudo $(which sshd)
