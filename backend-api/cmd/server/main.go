package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/lemra-org/essentiel_app/backend-api/internal/api"
	"github.com/lemra-org/essentiel_app/backend-api/internal/cache"
	"github.com/lemra-org/essentiel_app/backend-api/internal/config"
	"github.com/lemra-org/essentiel_app/backend-api/internal/sheets"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	log.Printf("Server starting on :%s", cfg.Port)
	log.Printf("Caching enabled with %v TTL", cfg.CacheTTL)
	log.Printf("CORS configured for: %s", cfg.AllowedOrigin)

	// Initialize Google Sheets client
	ctx := context.Background()
	sheetsClient, err := sheets.NewClient(ctx, cfg.ServiceAccountJSON, cfg.SpreadsheetID)
	if err != nil {
		log.Fatalf("Failed to create Google Sheets client: %v", err)
	}

	// Initialize cache
	cacheInstance := cache.New(cfg.CacheTTL)

	// Create router with handlers
	router := api.NewRouter(sheetsClient, cacheInstance)

	// Apply middleware
	handler := api.LoggingMiddleware(router)
	handler = api.CORSMiddleware(cfg.AllowedOrigin)(handler)

	// Create HTTP server
	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	serverErrors := make(chan error, 1)
	go func() {
		log.Printf("HTTP server listening on %s", server.Addr)
		serverErrors <- server.ListenAndServe()
	}()

	// Wait for interrupt signal for graceful shutdown
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		log.Fatalf("Server error: %v", err)
	case sig := <-shutdown:
		log.Printf("Received signal %v, shutting down gracefully...", sig)

		// Create shutdown context with timeout
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		// Attempt graceful shutdown
		if err := server.Shutdown(shutdownCtx); err != nil {
			log.Printf("Graceful shutdown failed: %v", err)
			server.Close()
		}

		log.Println("Server stopped")
	}
}
