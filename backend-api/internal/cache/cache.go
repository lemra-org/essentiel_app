package cache

import (
	"time"

	gocache "github.com/patrickmn/go-cache"
)

// Cache wraps an in-memory cache with TTL support
type Cache struct {
	cache *gocache.Cache
	ttl   time.Duration
}

// New creates a new cache with the specified TTL
func New(ttl time.Duration) *Cache {
	// Set cleanup interval to 110% of TTL to reduce overhead (5.5 min for 5 min TTL)
	cleanupInterval := ttl + (ttl / 10)

	return &Cache{
		cache: gocache.New(ttl, cleanupInterval),
		ttl:   ttl,
	}
}

// Get retrieves a value from the cache
func (c *Cache) Get(key string) (interface{}, bool) {
	return c.cache.Get(key)
}

// Set stores a value in the cache with the configured TTL
func (c *Cache) Set(key string, value interface{}) {
	c.cache.Set(key, value, c.ttl)
}

// Delete removes a value from the cache
func (c *Cache) Delete(key string) {
	c.cache.Delete(key)
}

// Clear removes all values from the cache
func (c *Cache) Clear() {
	c.cache.Flush()
}
