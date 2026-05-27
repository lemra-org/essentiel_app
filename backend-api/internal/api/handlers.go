package api

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/lemra-org/essentiel_app/backend-api/internal/cache"
	"github.com/lemra-org/essentiel_app/backend-api/internal/sheets"
)

// GetCategories handles GET /api/categories
func GetCategories(sheetsClient sheets.Fetcher, cacheInstance *cache.Cache) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		const cacheKey = "categories"

		// Check if refresh is requested (bypass cache)
		forceRefresh := r.URL.Query().Get("refresh") == "true"

		// Check cache first (unless refresh is forced)
		if !forceRefresh {
			if cached, found := cacheInstance.Get(cacheKey); found {
			var categories []sheets.Category

			// Handle both in-memory cache ([]sheets.Category) and Redis ([]interface{})
			switch v := cached.(type) {
			case []sheets.Category:
				categories = v
			case []interface{}:
				// Redis returns generic slice - convert to typed slice
				for _, item := range v {
					if itemMap, ok := item.(map[string]interface{}); ok {
						cat := sheets.Category{
							Name:  itemMap["name"].(string),
							Color: itemMap["color"].(string),
						}
						categories = append(categories, cat)
					}
				}
			default:
				// Invalid cache entry type, fetch fresh
				goto fetchFresh
			}

				w.Header().Set("Content-Type", "application/json; charset=utf-8")
				w.Header().Set("Cache-Control", "public, max-age=300")
				json.NewEncoder(w).Encode(map[string]interface{}{
					"categories": categories,
				})
				return
			}
		}

	fetchFresh:

		// Cache miss - fetch from Google Sheets
		categories, err := sheetsClient.FetchCategories(r.Context())
		if err != nil {
			log.Printf("Error fetching categories: %v", err)
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			w.WriteHeader(http.StatusServiceUnavailable)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Unable to fetch data from source",
			})
			return
		}

		// Store in cache
		cacheInstance.Set(cacheKey, categories)

		// Return response
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.Header().Set("Cache-Control", "public, max-age=300")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"categories": categories,
		})
	}
}

// GetQuestions handles GET /api/questions
func GetQuestions(sheetsClient sheets.Fetcher, cacheInstance *cache.Cache) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		const cacheKey = "questions"

		// Check if refresh is requested (bypass cache)
		forceRefresh := r.URL.Query().Get("refresh") == "true"

		// Check cache first (unless refresh is forced)
		if !forceRefresh {
			if cached, found := cacheInstance.Get(cacheKey); found {
			var questions []sheets.Question

			// Handle both in-memory cache ([]sheets.Question) and Redis ([]interface{})
			switch v := cached.(type) {
			case []sheets.Question:
				questions = v
			case []interface{}:
				// Redis returns generic slice - convert to typed slice
				for _, item := range v {
					if itemMap, ok := item.(map[string]interface{}); ok {
						q := sheets.Question{
							Question:    itemMap["question"].(string),
							Category:    itemMap["category"].(string),
							ForCouples:  itemMap["forCouples"].(bool),
							ForFamilies: itemMap["forFamilies"].(bool),
						}
						questions = append(questions, q)
					}
				}
			default:
				// Invalid cache entry type, fetch fresh
				goto fetchFresh
			}

				w.Header().Set("Content-Type", "application/json; charset=utf-8")
				w.Header().Set("Cache-Control", "public, max-age=300")
				json.NewEncoder(w).Encode(map[string]interface{}{
					"questions": questions,
				})
				return
			}
		}

	fetchFresh:

		// Cache miss - fetch from Google Sheets
		questions, err := sheetsClient.FetchQuestions(r.Context())
		if err != nil {
			log.Printf("Error fetching questions: %v", err)
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			w.WriteHeader(http.StatusServiceUnavailable)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Unable to fetch data from source",
			})
			return
		}

		// Store in cache
		cacheInstance.Set(cacheKey, questions)

		// Return response
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.Header().Set("Cache-Control", "public, max-age=300")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"questions": questions,
		})
	}
}

// Healthz handles GET /healthz (liveness probe)
func Healthz() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{
			"status": "healthy",
		})
	}
}

// Readyz handles GET /readyz (readiness probe)
func Readyz(sheetsClient sheets.Fetcher) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Test Google Sheets connectivity by attempting to fetch categories
		_, err := sheetsClient.FetchCategories(r.Context())

		w.Header().Set("Content-Type", "application/json; charset=utf-8")

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
