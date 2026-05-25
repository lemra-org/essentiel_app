package sheets

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"golang.org/x/oauth2/google"
	"google.golang.org/api/option"
	"google.golang.org/api/sheets/v4"
)

// Client wraps the Google Sheets API client
type Client struct {
	service       *sheets.Service
	spreadsheetID string
}

// NewClient creates a new Google Sheets client with Service Account authentication
func NewClient(ctx context.Context, serviceAccountJSON string, spreadsheetID string) (*Client, error) {
	creds, err := google.CredentialsFromJSON(ctx, []byte(serviceAccountJSON), sheets.SpreadsheetsReadonlyScope)
	if err != nil {
		return nil, fmt.Errorf("failed to parse service account credentials: %w", err)
	}

	service, err := sheets.NewService(ctx, option.WithCredentials(creds))
	if err != nil {
		return nil, fmt.Errorf("failed to create sheets service: %w", err)
	}

	return &Client{
		service:       service,
		spreadsheetID: spreadsheetID,
	}, nil
}

// FetchCategories reads the Categories sheet and returns parsed Category objects
func (c *Client) FetchCategories(ctx context.Context) ([]Category, error) {
	resp, err := c.service.Spreadsheets.Values.Get(c.spreadsheetID, "Categories!A:B").Context(ctx).Do()
	if err != nil {
		return nil, fmt.Errorf("failed to fetch categories: %w", err)
	}

	if len(resp.Values) <= 1 {
		return []Category{}, nil
	}

	categories := make([]Category, 0, len(resp.Values)-1)
	seen := make(map[string]bool)

	for i, row := range resp.Values {
		if i == 0 {
			continue
		}

		if len(row) < 2 {
			continue
		}

		name := toString(row[0])
		color := toString(row[1])

		if name == "" {
			continue
		}

		if seen[name] {
			continue
		}
		seen[name] = true

		if !isValidHexColor(color) {
			color = "#009688"
		}

		categories = append(categories, Category{
			Name:  name,
			Color: color,
		})
	}

	return categories, nil
}

// FetchQuestions reads the Questions sheet and returns parsed Question objects
func (c *Client) FetchQuestions(ctx context.Context) ([]Question, error) {
	resp, err := c.service.Spreadsheets.Values.Get(c.spreadsheetID, "Questions!A:D").Context(ctx).Do()
	if err != nil {
		return nil, fmt.Errorf("failed to fetch questions: %w", err)
	}

	if len(resp.Values) <= 1 {
		return []Question{}, nil
	}

	questions := make([]Question, 0, len(resp.Values)-1)

	for i, row := range resp.Values {
		if i == 0 {
			continue
		}

		if len(row) < 2 {
			continue
		}

		category := toString(row[0])
		questionText := toString(row[1])

		if questionText == "" || category == "" {
			continue
		}

		forCouples := false
		forFamilies := false
		if len(row) >= 3 {
			forCouples = toBool(row[2])
		}
		if len(row) >= 4 {
			forFamilies = toBool(row[3])
		}

		forParentChild := (category == "Parent - Enfant")

		questions = append(questions, Question{
			Question:       questionText,
			Category:       category,
			ForCouples:     forCouples,
			ForFamilies:    forFamilies,
			ForParentChild: forParentChild,
		})
	}

	return questions, nil
}

// Helper functions for data parsing and validation

var hexColorRegex = regexp.MustCompile(`^#[0-9A-Fa-f]{6}$`)

// toString converts a cell value to string
func toString(value interface{}) string {
	if value == nil {
		return ""
	}
	if s, ok := value.(string); ok {
		return strings.TrimSpace(s)
	}
	return fmt.Sprintf("%v", value)
}

// toBool converts a cell value to boolean (case-insensitive "Oui" = true)
func toBool(value interface{}) bool {
	s := toString(value)
	return strings.EqualFold(s, "Oui") || strings.EqualFold(s, "true") || s == "1"
}

// isValidHexColor validates hex color format
func isValidHexColor(color string) bool {
	return hexColorRegex.MatchString(color)
}
