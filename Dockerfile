# syntax=docker/dockerfile:1
# Initialize device type args
ARG USE_CUDA=false
ARG USE_OLLAMA=true
ARG USE_CUDA_VER=cu121
ARG USE_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
ARG USE_RERANKING_MODEL=""
ARG BUILD_HASH=dev-build
ARG UID=0
ARG GID=0

######## WebUI frontend ########
FROM --platform=$BUILDPLATFORM node:22-alpine3.20 AS build
ARG BUILD_HASH

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . ./openwebui
ENV APP_BUILD_HASH=${BUILD_HASH}
RUN npm run build

######## WebUI backend ########
FROM python:3.11-slim-bookworm AS base

# Use args
ARG USE_CUDA
ARG USE_OLLAMA
ARG USE_CUDA_VER
ARG USE_EMBEDDING_MODEL
ARG USE_RERANKING_MODEL
ARG UID
ARG GID

## Basis ##
ENV ENV=prod \
    PORT=3000 \
    USE_OLLAMA_DOCKER=${USE_OLLAMA} \
    USE_CUDA_DOCKER=${USE_CUDA} \
    USE_CUDA_DOCKER_VER=${USE_CUDA_VER} \
    USE_EMBEDDING_MODEL_DOCKER=${USE_EMBEDDING_MODEL} \
    USE_RERANKING_MODEL_DOCKER=${USE_RERANKING_MODEL}

## Basis URL Config ##
ENV OLLAMA_BASE_URL="/ollama" \
    OPENAI_API_BASE_URL=""

## API Key and Security Config ##
ENV OPENAI_API_KEY="" \
    WEBUI_SECRET_KEY="" \
    SCARF_NO_ANALYTICS=true \
    DO_NOT_TRACK=true \
    ANONYMIZED_TELEMETRY=false

#### Other models #########################################################
## whisper TTS model settings ##
ENV WHISPER_MODEL="base" \
    WHISPER_MODEL_DIR="/app/backend/data/cache/whisper/models"

## RAG Embedding model settings ##
ENV RAG_EMBEDDING_MODEL="$USE_EMBEDDING_MODEL_DOCKER" \
    RAG_RERANKING_MODEL="$USE_RERANKING_MODEL_DOCKER" \
    SENTENCE_TRANSFORMERS_HOME="/app/backend/data/cache/embedding/models"

## Hugging Face download cache ##
ENV HF_HOME="/app/backend/data/cache/embedding/models"

## Torch Extensions ##
ENV TORCH_EXTENSIONS_DIR="/.cache/torch_extensions"

#### Other models ##########################################################

WORKDIR /app/backend

ENV HOME=/root
# Create user and group if not root
RUN if [ $UID -ne 0 ]; then \
    if [ $GID -ne 0 ]; then \
    addgroup --gid $GID app; \
    fi; \
    adduser --uid $UID --gid $GID --home $HOME --disabled-password --no-create-home app; \
    fi

RUN mkdir -p $HOME/.cache/chroma
RUN echo -n 00000000-0000-0000-0000-000000000000 > $HOME/.cache/chroma/telemetry_user_id

# Make sure the user has access to the app and root directory
RUN chown -R $UID:$GID /app $HOME

RUN if [ "$USE_OLLAMA" = "true" ]; then \
    apt-get update && \
    # Install pandoc and netcat
    apt-get install -y --no-install-recommends git build-essential pandoc netcat-openbsd curl && \
    apt-get install -y --no-install-recommends gcc python3-dev && \
    # for RAG OCR
    apt-get install -y --no-install-recommends ffmpeg libsm6 libxext6 && \
    # install helper tools
    apt-get install -y --no-install-recommends curl jq && \
    # install ollama
    curl -fsSL https://ollama.com/install.sh | sh && \
    # cleanup
    rm -rf /var/lib/apt/lists/*; \
    else \
    apt-get update && \
    # Install pandoc, netcat and gcc
    apt-get install -y --no-install-recommends git build-essential pandoc gcc netcat-openbsd curl jq && \
    apt-get install -y --no-install-recommends gcc python3-dev && \
    # for RAG OCR
    apt-get install -y --no-install-recommends ffmpeg libsm6 libxext6 && \
    # cleanup
    rm -rf /var/lib/apt/lists/*; \
    fi

# install python dependencies directly
RUN pip install \
    fastapi==0.111.0 \
    uvicorn[standard]==0.30.6 \
    pydantic==2.9.2 \
    python-multipart==0.0.9 \
    Flask==3.0.3 \
    Flask-Cors==5.0.0 \
    python-socketio==5.11.3 \
    python-jose==3.3.0 \
    passlib[bcrypt]==1.7.4 \
    requests==2.32.3 \
    aiohttp==3.10.8 \
    sqlalchemy==2.0.32 \
    alembic==1.13.2 \
    peewee==3.17.6 \
    peewee-migrate==1.12.2 \
    psycopg2-binary==2.9.9 \
    PyMySQL==1.1.1 \
    bcrypt==4.2.0 \
    pymongo \
    redis \
    boto3==1.35.0 \
    argon2-cffi==23.1.0 \
    APScheduler==3.10.4 \
    openai \
    anthropic \
    google-generativeai==0.7.2 \
    tiktoken \
    langchain==0.2.15 \
    langchain-community==0.2.12 \
    langchain-chroma==0.1.4 \
    fake-useragent==1.5.1 \
    chromadb==0.5.9 \
    pymilvus==2.4.7 \
    sentence-transformers==3.0.1 \
    colbert-ai==0.2.21 \
    einops==0.8.0 \
    ftfy==6.2.3 \
    pypdf==4.3.1 \
    docx2txt==0.8 \
    python-pptx==1.0.0 \
    unstructured==0.15.9 \
    nltk==3.9.1 \
    Markdown==3.7 \
    pypandoc==1.13 \
    pandas==2.2.3 \
    openpyxl==3.1.5 \
    pyxlsb==1.0.10 \
    xlrd==2.0.1 \
    validators==0.33.0 \
    psutil \
    opencv-python-headless==4.10.0.84 \
    rapidocr-onnxruntime==1.3.24 \
    fpdf2==2.7.9 \
    rank-bm25==0.2.2 \
    faster-whisper==1.0.3 \
    PyJWT[crypto]==2.9.0 \
    authlib==1.3.2 \
    black==24.8.0 \
    langfuse==2.44.0 \
    youtube-transcript-api==0.6.2 \
    pytube==15.0.0 \
    extract_msg \
    pydub \
    duckduckgo-search~=6.2.13 \
    docker~=7.1.0 \
    pytest~=8.3.2 \
    pytest-docker~=3.1.1

# copy embedding weight from build
RUN mkdir -p /root/.cache/chroma/onnx_models/all-MiniLM-L6-v2
COPY --from=build /app/onnx /root/.cache/chroma/onnx_models/all-MiniLM-L6-v2/onnx

# copy built frontend files
COPY --chown=$UID:$GID --from=build /app/build /app/build
COPY --chown=$UID:$GID --from=build /app/CHANGELOG.md /app/CHANGELOG.md
COPY --chown=$UID:$GID --from=build /app/package.json /app/package.json

# copy backend files
COPY --chown=$UID:$GID ./backend .

EXPOSE 8000 3000 11434

HEALTHCHECK CMD curl --silent --fail http://localhost:${PORT:-8000}/health | jq -ne 'input.status == true' || exit 1

USER $UID:$GID

ARG BUILD_HASH
ENV WEBUI_BUILD_VERSION=${BUILD_HASH}
ENV DOCKER=true

CMD [ "bash", "start.sh"]
