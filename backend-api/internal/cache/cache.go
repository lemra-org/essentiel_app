package cache

import (
	"context"
	"encoding/json"
	"time"

	gocache "github.com/patrickmn/go-cache"
	"github.com/redis/go-redis/v9"
)

// Cache wraps either Redis or in-memory cache with TTL support
type Cache struct {
	redis       *redis.Client
	memoryCache *gocache.Cache
	ttl         time.Duration
}

// New creates a new cache with the specified TTL
// If redisAddr is empty, falls back to in-memory cache
func New(ttl time.Duration, redisAddr string) *Cache {
	c := &Cache{
		ttl: ttl,
	}

	// Try to connect to Redis if address is provided
	if redisAddr != "" {
		client := redis.NewClient(&redis.Options{
			Addr: redisAddr,
		})

		// Test connection
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		if err := client.Ping(ctx).Err(); err == nil {
			c.redis = client
			return c
		}
		// Redis connection failed, fall back to in-memory
		client.Close()
	}

	// Use in-memory cache as fallback
	cleanupInterval := ttl + (ttl / 10)
	c.memoryCache = gocache.New(ttl, cleanupInterval)

	return c
}

// Get retrieves a value from the cache
func (c *Cache) Get(key string) (interface{}, bool) {
	if c.redis != nil {
		return c.getRedis(key)
	}
	return c.memoryCache.Get(key)
}

// Set stores a value in the cache with the configured TTL
func (c *Cache) Set(key string, value interface{}) {
	if c.redis != nil {
		c.setRedis(key, value)
		return
	}
	c.memoryCache.Set(key, value, c.ttl)
}

// Delete removes a value from the cache
func (c *Cache) Delete(key string) {
	if c.redis != nil {
		c.redis.Del(context.Background(), key)
		return
	}
	c.memoryCache.Delete(key)
}

// Clear removes all values from the cache
func (c *Cache) Clear() {
	if c.redis != nil {
		c.redis.FlushDB(context.Background())
		return
	}
	c.memoryCache.Flush()
}

// Close closes the Redis connection if active
func (c *Cache) Close() error {
	if c.redis != nil {
		return c.redis.Close()
	}
	return nil
}

// getRedis retrieves and deserializes a value from Redis
// Returns []interface{} for arrays, map[string]interface{} for objects
func (c *Cache) getRedis(key string) (interface{}, bool) {
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	val, err := c.redis.Get(ctx, key).Bytes()
	if err != nil {
		return nil, false
	}

	var result interface{}
	if err := json.Unmarshal(val, &result); err != nil {
		return nil, false
	}

	return result, true
}

// setRedis serializes and stores a value in Redis
func (c *Cache) setRedis(key string, value interface{}) {
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	data, err := json.Marshal(value)
	if err != nil {
		return
	}

	c.redis.Set(ctx, key, data, c.ttl)
}
