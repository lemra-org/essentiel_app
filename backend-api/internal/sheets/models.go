package sheets

// Category represents a question category with visual styling
type Category struct {
	Name  string `json:"name"`
	Color string `json:"color"`
}

// Question represents a card question with category and context flags
type Question struct {
	Question   string `json:"question"`
	Category   string `json:"category"`
	ForCouples bool   `json:"forCouples"`
	ForParents bool   `json:"forParents"`
}
