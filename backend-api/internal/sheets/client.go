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
// Expected columns: Catégorie, Couleur (detected from header row)
func (c *Client) FetchCategories(ctx context.Context) ([]Category, error) {
	// Fetch all columns - header parsing will find the right ones by name
	resp, err := c.service.Spreadsheets.Values.Get(c.spreadsheetID, "Categories!A:Z").Context(ctx).Do()
	if err != nil {
		return nil, fmt.Errorf("failed to fetch categories: %w", err)
	}

	if len(resp.Values) <= 1 {
		return []Category{}, nil
	}

	// Parse header row to find column indices
	headers := resp.Values[0]
	categoryCol := -1
	colorCol := -1

	for i, header := range headers {
		h := toString(header)
		if h == "Catégorie" || h == "Category" {
			categoryCol = i
		} else if h == "Couleur" || h == "Color" {
			colorCol = i
		}
	}

	if categoryCol == -1 {
		// Fallback: assume first column is category
		categoryCol = 0
	}
	if colorCol == -1 {
		// Fallback: assume second column is color
		colorCol = 1
	}

	categories := make([]Category, 0, len(resp.Values)-1)
	seen := make(map[string]bool)

	for i, row := range resp.Values {
		if i == 0 {
			continue // Skip header row
		}

		if len(row) <= categoryCol {
			continue
		}

		name := toString(row[categoryCol])
		if name == "" {
			continue
		}

		if seen[name] {
			continue
		}
		seen[name] = true

		color := "#009688" // Default teal
		if len(row) > colorCol {
			colorValue := toString(row[colorCol])
			// Add # prefix if missing
			if colorValue != "" && !strings.HasPrefix(colorValue, "#") {
				colorValue = "#" + colorValue
			}
			if isValidHexColor(colorValue) {
				color = colorValue
			}
		}

		categories = append(categories, Category{
			Name:  name,
			Color: color,
		})
	}

	return categories, nil
}

// FetchQuestions reads the Questions sheet and returns parsed Question objects
// Expected columns: Catégorie, Question, Pour Couples, Pour Familles (detected from header row)
func (c *Client) FetchQuestions(ctx context.Context) ([]Question, error) {
	// Fetch all columns - header parsing will find the right ones by name
	resp, err := c.service.Spreadsheets.Values.Get(c.spreadsheetID, "Questions!A:Z").Context(ctx).Do()
	if err != nil {
		return nil, fmt.Errorf("failed to fetch questions: %w", err)
	}

	if len(resp.Values) <= 1 {
		return []Question{}, nil
	}

	// Parse header row to find column indices
	headers := resp.Values[0]
	categoryCol := -1
	questionCol := -1
	couplesCol := -1
	familiesCol := -1

	for i, header := range headers {
		h := toString(header)
		switch h {
		case "Catégorie", "Category":
			categoryCol = i
		case "Question":
			questionCol = i
		case "Pour Couples", "For Couples":
			couplesCol = i
		case "Pour Familles", "For Families":
			familiesCol = i
		}
	}

	// Fallback to positional if headers not found
	if categoryCol == -1 {
		categoryCol = 0
	}
	if questionCol == -1 {
		questionCol = 1
	}
	if couplesCol == -1 {
		couplesCol = 2
	}
	if familiesCol == -1 {
		familiesCol = 3
	}

	questions := make([]Question, 0, len(resp.Values)-1)

	for i, row := range resp.Values {
		if i == 0 {
			continue // Skip header row
		}

		if len(row) <= categoryCol || len(row) <= questionCol {
			continue
		}

		category := toString(row[categoryCol])
		questionText := toString(row[questionCol])

		if questionText == "" || category == "" {
			continue
		}

		forCouples := false
		forFamilies := false
		if len(row) > couplesCol {
			forCouples = toBool(row[couplesCol])
		}
		if len(row) > familiesCol {
			forFamilies = toBool(row[familiesCol])
		}

		// Parent-child questions are inherently family questions
		if category == "Parent - Enfant" {
			forFamilies = true
		}

		questions = append(questions, Question{
			Question:    questionText,
			Category:    category,
			ForCouples:  forCouples,
			ForFamilies: forFamilies,
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
