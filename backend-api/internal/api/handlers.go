package api

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"github.com/lemra-org/essentiel_app/backend-api/internal/cache"
	"github.com/lemra-org/essentiel_app/backend-api/internal/sheets"
)

// GetCategories handles GET /api/categories
func GetCategories(sheetsClient *sheets.Client, cacheInstance *cache.Cache) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		const cacheKey = "categories"

		// Check cache first
		if cached, found := cacheInstance.Get(cacheKey); found {
			if categories, ok := cached.([]sheets.Category); ok {
				w.Header().Set("Content-Type", "application/json")
				w.Header().Set("Cache-Control", "public, max-age=300")
				json.NewEncoder(w).Encode(map[string]interface{}{
					"categories": categories,
				})
				return
			}
		}

		// Cache miss - fetch from Google Sheets
		categories, err := sheetsClient.FetchCategories(context.Background())
		if err != nil {
			log.Printf("Error fetching categories: %v", err)
			http.Error(w, `{"error":"Unable to fetch data from source"}`, http.StatusServiceUnavailable)
			return
		}

		// Store in cache
		cacheInstance.Set(cacheKey, categories)

		// Return response
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "public, max-age=300")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"categories": categories,
		})
	}
}

// GetQuestions handles GET /api/questions
func GetQuestions(sheetsClient *sheets.Client, cacheInstance *cache.Cache) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		const cacheKey = "questions"

		// Check cache first
		if cached, found := cacheInstance.Get(cacheKey); found {
			if questions, ok := cached.([]sheets.Question); ok {
				w.Header().Set("Content-Type", "application/json")
				w.Header().Set("Cache-Control", "public, max-age=300")
				json.NewEncoder(w).Encode(map[string]interface{}{
					"questions": questions,
				})
				return
			}
		}

		// Cache miss - fetch from Google Sheets
		questions, err := sheetsClient.FetchQuestions(context.Background())
		if err != nil {
			log.Printf("Error fetching questions: %v", err)
			http.Error(w, `{"error":"Unable to fetch data from source"}`, http.StatusServiceUnavailable)
			return
		}

		// Store in cache
		cacheInstance.Set(cacheKey, questions)

		// Return response
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "public, max-age=300")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"questions": questions,
		})
	}
}

// Healthz handles GET /healthz (liveness probe)
func Healthz() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{
			"status": "healthy",
		})
	}
}

// Readyz handles GET /readyz (readiness probe)
func Readyz(sheetsClient *sheets.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Test Google Sheets connectivity by attempting to fetch a small range
		ctx := context.Background()
		_, err := sheetsClient.FetchCategories(ctx)

		w.Header().Set("Content-Type", "application/json")

		if err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			json.NewEncoder(w).Encode(map[string]string{
				"status": "not ready",
			})
			return
		}

		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{
			"status": "ready",
		})
	}
}
