# Use the open-webui Ollama image from GHCR
FROM ghcr.io/open-webui/open-webui:ollama

# Install sudo (if it isn't already installed in the base image)
RUN apt-get update && apt-get install -y sudo

# Copy the start.sh script into the container
COPY start.sh /usr/local/bin/start.sh

# Make start.sh executable
RUN chmod +x /usr/local/bin/start.sh

# Set the entrypoint to the start.sh script
ENTRYPOINT ["/usr/local/bin/start.sh"]
