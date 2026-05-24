package api

import (
	"net/http"

	"github.com/lemra-org/essentiel_app/backend-api/internal/cache"
	"github.com/lemra-org/essentiel_app/backend-api/internal/sheets"
)

// Router holds dependencies for HTTP handlers
type Router struct {
	sheetsClient sheets.Fetcher
	cache        *cache.Cache
	mux          *http.ServeMux
}

// NewRouter creates a new HTTP router with registered endpoints
func NewRouter(sheetsClient sheets.Fetcher, cache *cache.Cache) *Router {
	r := &Router{
		sheetsClient: sheetsClient,
		cache:        cache,
		mux:          http.NewServeMux(),
	}

	// Register API endpoints
	r.mux.HandleFunc("/api/categories", GetCategories(sheetsClient, cache))
	r.mux.HandleFunc("/api/questions", GetQuestions(sheetsClient, cache))

	// Register health check endpoints
	r.mux.HandleFunc("/healthz", Healthz())
	r.mux.HandleFunc("/readyz", Readyz(sheetsClient))

	return r
}

// ServeHTTP implements http.Handler interface
func (r *Router) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	r.mux.ServeHTTP(w, req)
}
