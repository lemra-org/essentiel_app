package config

import (
	"os"
	"testing"
	"time"
)

func TestLoad_AllDefaults(t *testing.T) {
	// Clear environment
	os.Clearenv()

	// Set required variables
	os.Setenv("GOOGLE_SERVICE_ACCOUNT_JSON", `{"type":"service_account"}`)
	os.Setenv("GOOGLE_SPREADSHEET_ID", "test-spreadsheet-id")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	if cfg.Port != "8080" {
		t.Errorf("Expected default port 8080, got %s", cfg.Port)
	}

	if cfg.AllowedOrigin != "https://lemra-org.github.io" {
		t.Errorf("Expected default origin, got %s", cfg.AllowedOrigin)
	}

	if cfg.CacheTTL != 5*time.Minute {
		t.Errorf("Expected default cache TTL 5m, got %v", cfg.CacheTTL)
	}

	if cfg.ServiceAccountJSON != `{"type":"service_account"}` {
		t.Errorf("Service account JSON mismatch")
	}

	if cfg.SpreadsheetID != "test-spreadsheet-id" {
		t.Errorf("Spreadsheet ID mismatch")
	}
}

func TestLoad_CustomValues(t *testing.T) {
	os.Clearenv()

	os.Setenv("PORT", "9000")
	os.Setenv("GOOGLE_SERVICE_ACCOUNT_JSON", `{"type":"custom"}`)
	os.Setenv("GOOGLE_SPREADSHEET_ID", "custom-id")
	os.Setenv("ALLOWED_ORIGIN", "https://custom.com")
	os.Setenv("CACHE_TTL_MINUTES", "10")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	if cfg.Port != "9000" {
		t.Errorf("Expected port 9000, got %s", cfg.Port)
	}

	if cfg.AllowedOrigin != "https://custom.com" {
		t.Errorf("Expected custom origin, got %s", cfg.AllowedOrigin)
	}

	if cfg.CacheTTL != 10*time.Minute {
		t.Errorf("Expected cache TTL 10m, got %v", cfg.CacheTTL)
	}
}

func TestLoad_MissingServiceAccount(t *testing.T) {
	os.Clearenv()
	os.Setenv("GOOGLE_SPREADSHEET_ID", "test-id")

	_, err := Load()
	if err == nil {
		t.Error("Expected error for missing service account, got nil")
	}

	if configErr, ok := err.(*ConfigError); ok {
		if configErr.Field != "GOOGLE_SERVICE_ACCOUNT_JSON" {
			t.Errorf("Expected error for GOOGLE_SERVICE_ACCOUNT_JSON, got %s", configErr.Field)
		}
	} else {
		t.Error("Expected ConfigError type")
	}
}

func TestLoad_MissingSpreadsheetID(t *testing.T) {
	os.Clearenv()
	os.Setenv("GOOGLE_SERVICE_ACCOUNT_JSON", `{"type":"service_account"}`)

	_, err := Load()
	if err == nil {
		t.Error("Expected error for missing spreadsheet ID, got nil")
	}

	if configErr, ok := err.(*ConfigError); ok {
		if configErr.Field != "GOOGLE_SPREADSHEET_ID" {
			t.Errorf("Expected error for GOOGLE_SPREADSHEET_ID, got %s", configErr.Field)
		}
	} else {
		t.Error("Expected ConfigError type")
	}
}

func TestLoad_InvalidCacheTTL(t *testing.T) {
	os.Clearenv()
	os.Setenv("GOOGLE_SERVICE_ACCOUNT_JSON", `{"type":"service_account"}`)
	os.Setenv("GOOGLE_SPREADSHEET_ID", "test-id")
	os.Setenv("CACHE_TTL_MINUTES", "invalid")

	_, err := Load()
	if err == nil {
		t.Error("Expected error for invalid cache TTL, got nil")
	}

	if configErr, ok := err.(*ConfigError); ok {
		if configErr.Field != "CACHE_TTL_MINUTES" {
			t.Errorf("Expected error for CACHE_TTL_MINUTES, got %s", configErr.Field)
		}
	} else {
		t.Error("Expected ConfigError type")
	}
}

func TestConfigError_Error(t *testing.T) {
	err := &ConfigError{
		Field:   "TEST_FIELD",
		Message: "test message",
	}

	expected := "config error: TEST_FIELD: test message"
	if err.Error() != expected {
		t.Errorf("Expected error message %q, got %q", expected, err.Error())
	}
}
