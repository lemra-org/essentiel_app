package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all configuration for the backend API service
type Config struct {
	Port               string
	ServiceAccountJSON string
	SpreadsheetID      string
	AllowedOrigin      string
	CacheTTL           time.Duration
	RedisAddr          string
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	serviceAccountJSON := os.Getenv("GOOGLE_SERVICE_ACCOUNT_JSON")
	if serviceAccountJSON == "" {
		return nil, &ConfigError{Field: "GOOGLE_SERVICE_ACCOUNT_JSON", Message: "required environment variable not set"}
	}

	spreadsheetID := os.Getenv("GOOGLE_SPREADSHEET_ID")
	if spreadsheetID == "" {
		return nil, &ConfigError{Field: "GOOGLE_SPREADSHEET_ID", Message: "required environment variable not set"}
	}

	allowedOrigin := os.Getenv("ALLOWED_ORIGIN")
	if allowedOrigin == "" {
		allowedOrigin = "https://lemra-org.github.io"
	}

	cacheTTLMinutes := os.Getenv("CACHE_TTL_MINUTES")
	if cacheTTLMinutes == "" {
		cacheTTLMinutes = "5"
	}

	ttlMinutes, err := strconv.Atoi(cacheTTLMinutes)
	if err != nil {
		return nil, &ConfigError{Field: "CACHE_TTL_MINUTES", Message: "must be a valid integer"}
	}

	redisAddr := os.Getenv("REDIS_ADDR")
	// Redis is optional - if not set, in-memory cache will be used

	return &Config{
		Port:               port,
		ServiceAccountJSON: serviceAccountJSON,
		SpreadsheetID:      spreadsheetID,
		AllowedOrigin:      allowedOrigin,
		CacheTTL:           time.Duration(ttlMinutes) * time.Minute,
		RedisAddr:          redisAddr,
	}, nil
}

// ConfigError represents a configuration loading error
type ConfigError struct {
	Field   string
	Message string
}

func (e *ConfigError) Error() string {
	return "config error: " + e.Field + ": " + e.Message
}
