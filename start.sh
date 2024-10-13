#!/usr/bin/env bash

# Start the Ollama service if configured
if [[ "${USE_OLLAMA_DOCKER,,}" == "true" ]]; then
    echo "Starting Ollama service..."
    ollama serve &
fi

# Start the frontend
echo "Starting frontend..."
npm run build
npm run preview &

# Start the backend
echo "Starting backend..."
cd backend
bash start.sh &
wait -n

# Exit with status of the first process to exit
exit $?
