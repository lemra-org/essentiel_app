package api

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/lemra-org/essentiel_app/backend-api/internal/cache"
	"github.com/lemra-org/essentiel_app/backend-api/internal/sheets"
)

// mockSheetsClient implements a mock Google Sheets client for testing
type mockSheetsClient struct {
	categories []sheets.Category
	questions  []sheets.Question
	shouldFail bool
}

func (m *mockSheetsClient) FetchCategories(ctx context.Context) ([]sheets.Category, error) {
	if m.shouldFail {
		return nil, context.DeadlineExceeded
	}
	return m.categories, nil
}

func (m *mockSheetsClient) FetchQuestions(ctx context.Context) ([]sheets.Question, error) {
	if m.shouldFail {
		return nil, context.DeadlineExceeded
	}
	return m.questions, nil
}

func TestGetCategories_Success(t *testing.T) {
	mockClient := &mockSheetsClient{
		categories: []sheets.Category{
			{Name: "Famille", Color: "#FF9800"},
			{Name: "Couple", Color: "#E91E63"},
		},
	}
	testCache := cache.New(5*time.Minute, "")

	handler := GetCategories(mockClient, testCache)
	req := httptest.NewRequest("GET", "/api/categories", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, w.Code)
	}

	contentType := w.Header().Get("Content-Type")
	if contentType != "application/json; charset=utf-8" {
		t.Errorf("Expected Content-Type application/json; charset=utf-8, got %s", contentType)
	}

	cacheControl := w.Header().Get("Cache-Control")
	if cacheControl != "public, max-age=300" {
		t.Errorf("Expected Cache-Control public, max-age=300, got %s", cacheControl)
	}

	var response map[string][]sheets.Category
	if err := json.NewDecoder(w.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	categories, ok := response["categories"]
	if !ok {
		t.Fatal("Response missing 'categories' field")
	}

	if len(categories) != 2 {
		t.Errorf("Expected 2 categories, got %d", len(categories))
	}

	if categories[0].Name != "Famille" || categories[0].Color != "#FF9800" {
		t.Errorf("Category data mismatch: got %+v", categories[0])
	}
}

func TestGetCategories_CacheHit(t *testing.T) {
	mockClient := &mockSheetsClient{
		categories: []sheets.Category{
			{Name: "Original", Color: "#000000"},
		},
	}
	testCache := cache.New(5*time.Minute, "")

	// Pre-populate cache with different data
	cachedCategories := []sheets.Category{
		{Name: "Cached", Color: "#FFFFFF"},
	}
	testCache.Set("categories", cachedCategories)

	handler := GetCategories(mockClient, testCache)
	req := httptest.NewRequest("GET", "/api/categories", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	var response map[string][]sheets.Category
	json.NewDecoder(w.Body).Decode(&response)

	categories := response["categories"]
	if len(categories) != 1 || categories[0].Name != "Cached" {
		t.Error("Expected to receive cached data, got fresh data instead")
	}
}

func TestGetCategories_Error(t *testing.T) {
	mockClient := &mockSheetsClient{
		shouldFail: true,
	}
	testCache := cache.New(5*time.Minute, "")

	handler := GetCategories(mockClient, testCache)
	req := httptest.NewRequest("GET", "/api/categories", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusServiceUnavailable {
		t.Errorf("Expected status %d, got %d", http.StatusServiceUnavailable, w.Code)
	}

	contentType := w.Header().Get("Content-Type")
	if contentType != "application/json; charset=utf-8" {
		t.Errorf("Expected Content-Type application/json; charset=utf-8, got %s", contentType)
	}

	var response map[string]string
	if err := json.NewDecoder(w.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode error response: %v", err)
	}

	if response["error"] != "Unable to fetch data from source" {
		t.Errorf("Expected error message, got: %s", response["error"])
	}
}

func TestGetQuestions_Success(t *testing.T) {
	mockClient := &mockSheetsClient{
		questions: []sheets.Question{
			{
				Category:   "Choisis la vie",
				Question:   "Je partage une chose qui me remplit de joie",
				ForCouples: false,
				ForParents: false,
			},
			{
				Category:   "Parent - Enfant",
				Question:   "Quel animal aimerais-tu être pour une journée ?",
				ForCouples: false,
				ForParents: true,
			},
		},
	}
	testCache := cache.New(5*time.Minute, "")

	handler := GetQuestions(mockClient, testCache)
	req := httptest.NewRequest("GET", "/api/questions", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, w.Code)
	}

	var response map[string][]sheets.Question
	json.NewDecoder(w.Body).Decode(&response)

	questions := response["questions"]
	if len(questions) != 2 {
		t.Errorf("Expected 2 questions, got %d", len(questions))
	}

	if questions[0].Category != "Choisis la vie" {
		t.Errorf("Category mismatch: got %s", questions[0].Category)
	}

	if questions[1].Category != "Parent - Enfant" || !questions[1].ForParents {
		t.Errorf("Parent-Enfant question should have forParents=true: %+v", questions[1])
	}
}

func TestHealthz(t *testing.T) {
	handler := Healthz()
	req := httptest.NewRequest("GET", "/healthz", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, w.Code)
	}

	var response map[string]string
	json.NewDecoder(w.Body).Decode(&response)

	if response["status"] != "healthy" {
		t.Errorf("Expected status 'healthy', got %s", response["status"])
	}
}

func TestReadyz_Success(t *testing.T) {
	mockClient := &mockSheetsClient{
		categories: []sheets.Category{
			{Name: "Test", Color: "#000000"},
		},
	}

	handler := Readyz(mockClient)
	req := httptest.NewRequest("GET", "/readyz", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status %d, got %d", http.StatusOK, w.Code)
	}

	var response map[string]string
	json.NewDecoder(w.Body).Decode(&response)

	if response["status"] != "ready" {
		t.Errorf("Expected status 'ready', got %s", response["status"])
	}
}

func TestReadyz_NotReady(t *testing.T) {
	mockClient := &mockSheetsClient{
		shouldFail: true,
	}

	handler := Readyz(mockClient)
	req := httptest.NewRequest("GET", "/readyz", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusServiceUnavailable {
		t.Errorf("Expected status %d, got %d", http.StatusServiceUnavailable, w.Code)
	}

	var response map[string]string
	json.NewDecoder(w.Body).Decode(&response)

	if response["status"] != "not ready" {
		t.Errorf("Expected status 'not ready', got %s", response["status"])
	}
}
