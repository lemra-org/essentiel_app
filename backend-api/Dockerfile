# Build stage
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary with optimizations
# CGO_ENABLED=0 for static linking
# -ldflags="-s -w" strips debug information
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server ./cmd/server

# Runtime stage
FROM gcr.io/distroless/static-debian12

# Copy binary from builder
COPY --from=builder /app/server /server

# Run as non-root user
USER 65532:65532

# Expose port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/server"]
