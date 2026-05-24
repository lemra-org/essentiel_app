package sheets

import "context"

// Fetcher defines the interface for fetching data from Google Sheets
type Fetcher interface {
	FetchCategories(ctx context.Context) ([]Category, error)
	FetchQuestions(ctx context.Context) ([]Question, error)
}
