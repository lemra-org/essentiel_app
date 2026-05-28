#!/bin/sh
set -e

# Default backend URL if not provided
BACKEND_URL=${BACKEND_URL:-http://backend-api:8080}

# Select nginx config based on BUILD_ENV (dev = no caching, prod = aggressive caching)
BUILD_ENV=${BUILD_ENV:-prod}

if [ "$BUILD_ENV" = "dev" ]; then
    echo "Using DEVELOPMENT nginx config (no caching for easier testing)"
    CONFIG_TEMPLATE="/etc/nginx/nginx-dev.conf.template"
else
    echo "Using PRODUCTION nginx config (aggressive caching)"
    CONFIG_TEMPLATE="/etc/nginx/nginx-prod.conf.template"
fi

echo "Configuring nginx with backend URL: $BACKEND_URL"

# Substitute environment variables in nginx config
envsubst '${BACKEND_URL}' < "$CONFIG_TEMPLATE" > /etc/nginx/conf.d/default.conf

# Start nginx
exec nginx -g 'daemon off;'
