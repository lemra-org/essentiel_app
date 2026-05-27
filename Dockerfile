# Multi-stage Dockerfile for Flutter web build

# Stage 1: Build Flutter web app
FROM ubuntu:24.04 AS flutter-builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ENV FLUTTER_VERSION=3.22.3
RUN git clone https://github.com/flutter/flutter.git /flutter && \
    cd /flutter && \
    git checkout ${FLUTTER_VERSION} && \
    /flutter/bin/flutter --version

ENV PATH="/flutter/bin:${PATH}"

# Set up Flutter
WORKDIR /app
RUN flutter config --enable-web --no-analytics

# Copy dependency files
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code
COPY . .

# Build for production
ARG BUILD_ENV=prod
RUN flutter build web \
    --release \
    --base-href="/" \
    --tree-shake-icons \
    -t lib/environments/web_${BUILD_ENV}.dart

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy Flutter web build
COPY --from=flutter-builder /app/build/web /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
