-- cache.lua -- aquietone
-- LRU cache implementation.

---@class Cache
local Cache = {
    ---Number of entries to allow in the cache before removing old entries
    maxsize=200,
    ---Minimum age, in seconds, of entries to be removed when the cache is pruned
    expiration=300,
    ---The cached key/value pairs
    data={},
}

---Initialize a new cache istance.
---@param maxsize number @
---@param expiration number @
---@return Cache @The cache instance.
function Cache:new(maxsize, expiration)
    local c = {}
    setmetatable(c, self)
    self.__index = self
    c.maxsize = maxsize
    c.expiration = expiration
    return c
end

---Returns the number of entries in the cache
---@return number @The number of entries in the cache
function Cache:size()
    local size = 0
    for _,_ in pairs(self.data) do
        size = size+1
    end
    return size
end

---Remove least recently used entries from the cache if maximum size is exceeded
function Cache:clean()
    local size = self:size()
    if size > self.maxsize then
        --local numremoved = 0
        for key,value in pairs(self.data) do
            if os.difftime(os.time(), value.lastaccessed) > self.expiration then
                --print(string.format('Removing cached entry: %s=%s', key, self.data[key]))
                self.data[key] = nil
                --numremoved = numremoved+1
            end
        end
        --if numremoved > 0 then
        --    print(string.format('Cache size before: %d, Cache size after: %d', size, size-numremoved))
        --end
    end
end

---@param key string @The key to lookup from the cache
---@param callable function @The hard way to load the value if the key is not present
---@return any @The value if it exists in the cache or was retrieved, else nil
function Cache:get(key, callable)
    if self.data[key] then
        self.data[key].lastaccessed = os.time()
        return self.data[key].value
    end
    if callable then
        self.data[key] = {
            value = callable(),
            lastaccessed = os.time(),
        }
        return self.data[key].value
    end
end

return Cache
