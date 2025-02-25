FROM alpine:3 AS builder

ARG SEMGREP_VERSION=1.109.0

RUN apk --no-cache --update add python3 py3-pip py3-virtualenv gcc musl-dev python3-dev && \
    python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    python3 -m pip install --no-cache-dir semgrep=="$SEMGREP_VERSION"

FROM ghcr.io/orcasecurity/orca-cli:1

RUN apk --no-cache --update add bash nodejs npm python3 sqlite sqlite-dev

# Copy ONLY the virtual environment from the build stage, not the build tools
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
# Docker tries to cache each layer as much as possible, to increase building speed.
# Therefore, commands which change rarely, must be in the beginning.
COPY package*.json ./
# Install dependencies using npm ci instead of npm install to avoid packages updating accidentally
RUN npm ci
# Copy the js source code to the image:
COPY ./src ./src

WORKDIR /
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
