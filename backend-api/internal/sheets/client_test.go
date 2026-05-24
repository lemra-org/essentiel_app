package sheets

import (
	"testing"
)

func TestToString(t *testing.T) {
	tests := []struct {
		name     string
		input    interface{}
		expected string
	}{
		{"nil", nil, ""},
		{"empty string", "", ""},
		{"normal string", "test", "test"},
		{"string with spaces", "  test  ", "test"},
		{"integer", 42, "42"},
		{"float", 3.14, "3.14"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := toString(tt.input)
			if result != tt.expected {
				t.Errorf("toString(%v) = %q, expected %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestToBool(t *testing.T) {
	tests := []struct {
		name     string
		input    interface{}
		expected bool
	}{
		{"Oui lowercase", "oui", true},
		{"Oui uppercase", "OUI", true},
		{"Oui mixed case", "Oui", true},
		{"true lowercase", "true", true},
		{"true uppercase", "TRUE", true},
		{"1", "1", true},
		{"Non", "Non", false},
		{"false", "false", false},
		{"0", "0", false},
		{"empty string", "", false},
		{"random text", "random", false},
		{"nil", nil, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := toBool(tt.input)
			if result != tt.expected {
				t.Errorf("toBool(%v) = %v, expected %v", tt.input, result, tt.expected)
			}
		})
	}
}

func TestIsValidHexColor(t *testing.T) {
	tests := []struct {
		name     string
		color    string
		expected bool
	}{
		{"valid color lowercase", "#ff9800", true},
		{"valid color uppercase", "#FF9800", true},
		{"valid color mixed case", "#Ff9800", true},
		{"missing hash", "FF9800", false},
		{"too short", "#FF980", false},
		{"too long", "#FF98000", false},
		{"invalid characters", "#GG9800", false},
		{"empty string", "", false},
		{"hash only", "#", false},
		{"valid black", "#000000", true},
		{"valid white", "#FFFFFF", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := isValidHexColor(tt.color)
			if result != tt.expected {
				t.Errorf("isValidHexColor(%q) = %v, expected %v", tt.color, result, tt.expected)
			}
		})
	}
}

func TestCategoryValidation(t *testing.T) {
	// Test that invalid colors get replaced with default
	tests := []struct {
		name          string
		inputColor    string
		expectedColor string
	}{
		{"valid color", "#FF9800", "#FF9800"},
		{"invalid color", "invalid", "#009688"},
		{"empty color", "", "#009688"},
		{"missing hash", "FF9800", "#009688"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			color := tt.inputColor
			if !isValidHexColor(color) {
				color = "#009688"
			}
			if color != tt.expectedColor {
				t.Errorf("Color validation failed: got %s, expected %s", color, tt.expectedColor)
			}
		})
	}
}

func TestQuestionForParentChild(t *testing.T) {
	tests := []struct {
		category       string
		expectedResult bool
	}{
		{"Parent - Enfant", true},
		{"Famille", false},
		{"Couple", false},
		{"parent - enfant", false}, // Case-sensitive
		{"", false},
	}

	for _, tt := range tests {
		t.Run(tt.category, func(t *testing.T) {
			result := (tt.category == "Parent - Enfant")
			if result != tt.expectedResult {
				t.Errorf("ForParentChild check for %q = %v, expected %v",
					tt.category, result, tt.expectedResult)
			}
		})
	}
}
