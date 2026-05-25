package cache

import (
	"testing"
	"time"
)

func TestCache_SetAndGet(t *testing.T) {
	c := New(5*time.Minute, "")

	// Test setting and getting a value
	c.Set("key1", "value1")
	value, found := c.Get("key1")

	if !found {
		t.Error("Expected to find key1, but it was not found")
	}

	if value != "value1" {
		t.Errorf("Expected value1, got %v", value)
	}
}

func TestCache_GetNonExistent(t *testing.T) {
	c := New(5*time.Minute, "")

	_, found := c.Get("nonexistent")

	if found {
		t.Error("Expected not to find nonexistent key, but it was found")
	}
}

func TestCache_Delete(t *testing.T) {
	c := New(5*time.Minute, "")

	c.Set("key1", "value1")
	c.Delete("key1")

	_, found := c.Get("key1")
	if found {
		t.Error("Expected key1 to be deleted, but it was found")
	}
}

func TestCache_Clear(t *testing.T) {
	c := New(5*time.Minute, "")

	c.Set("key1", "value1")
	c.Set("key2", "value2")
	c.Clear()

	_, found1 := c.Get("key1")
	_, found2 := c.Get("key2")

	if found1 || found2 {
		t.Error("Expected cache to be cleared, but keys were found")
	}
}

func TestCache_Expiration(t *testing.T) {
	// Use a very short TTL for testing
	c := New(100*time.Millisecond, "")

	c.Set("key1", "value1")

	// Should be available immediately
	_, found := c.Get("key1")
	if !found {
		t.Error("Expected to find key1 immediately after setting")
	}

	// Wait for expiration
	time.Sleep(150 * time.Millisecond)

	_, found = c.Get("key1")
	if found {
		t.Error("Expected key1 to be expired, but it was found")
	}
}

func TestCache_MultipleTypes(t *testing.T) {
	c := New(5*time.Minute, "")

	// Test with different types
	c.Set("string", "value")
	c.Set("int", 42)
	c.Set("struct", struct{ Name string }{"test"})

	strValue, found := c.Get("string")
	if !found || strValue != "value" {
		t.Error("Failed to retrieve string value")
	}

	intValue, found := c.Get("int")
	if !found || intValue != 42 {
		t.Error("Failed to retrieve int value")
	}

	structValue, found := c.Get("struct")
	if !found {
		t.Error("Failed to retrieve struct value")
	}
	if s, ok := structValue.(struct{ Name string }); !ok || s.Name != "test" {
		t.Error("Failed to retrieve correct struct value")
	}
}
