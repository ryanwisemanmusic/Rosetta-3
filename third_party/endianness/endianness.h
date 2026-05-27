// Copyright © 2019 Aleksey Nikolaev
// License MIT: http://opensource.org/licenses/MIT
// endianness_xenia.h

#pragma once

#include <cstdint>
#include <cstring>
#include <type_traits>

namespace xe {
namespace endian {

// Simple byte swapping without fold expressions
template<typename T>
constexpr T byte_swap(T value) noexcept {
    static_assert(std::is_integral<T>::value || std::is_enum<T>::value,
                  "byte_swap requires integral or enum type");
    
    if constexpr (sizeof(T) == 1) {
        return value;
    } else if constexpr (sizeof(T) == 2) {
        return static_cast<T>((value << 8) | (value >> 8));
    } else if constexpr (sizeof(T) == 4) {
        uint32_t v = static_cast<uint32_t>(value);
        v = ((v & 0xFF000000) >> 24) |
            ((v & 0x00FF0000) >> 8)  |
            ((v & 0x0000FF00) << 8)  |
            ((v & 0x000000FF) << 24);
        return static_cast<T>(v);
    } else if constexpr (sizeof(T) == 8) {
        uint64_t v = static_cast<uint64_t>(value);
        v = ((v & 0xFF00000000000000ull) >> 56) |
            ((v & 0x00FF000000000000ull) >> 40) |
            ((v & 0x0000FF0000000000ull) >> 24) |
            ((v & 0x000000FF00000000ull) >> 8)  |
            ((v & 0x00000000FF000000ull) << 8)  |
            ((v & 0x0000000000FF0000ull) << 24) |
            ((v & 0x000000000000FF00ull) << 40) |
            ((v & 0x00000000000000FFull) << 56);
        return static_cast<T>(v);
    }
}

// Simple big-endian storage type (like the original but simplified)
template<typename T>
struct BigEndian {
    static_assert(sizeof(T) <= 8, "Type too large");
    static_assert(std::is_standard_layout<T>::value, "Type must be standard layout");
    
    T value;
    
    constexpr BigEndian() noexcept : value(T()) {}
    constexpr BigEndian(T val) noexcept : 
        value(is_little_endian() ? byte_swap(val) : val) {}
    
    // Load from memory
    static BigEndian load(const void* ptr) noexcept {
        BigEndian result;
        std::memcpy(&result.value, ptr, sizeof(T));
        if (is_little_endian()) {
            result.value = byte_swap(result.value);
        }
        return result;
    }
    
    // Store to memory
    void store(void* ptr) const noexcept {
        T val = is_little_endian() ? byte_swap(value) : value;
        std::memcpy(ptr, &val, sizeof(T));
    }
    
    // Convert to host
    T to_host() const noexcept {
        return is_little_endian() ? byte_swap(value) : value;
    }
    
    // Simple operator for conversion
    operator T() const noexcept { return to_host(); }
    
private:
    static constexpr bool is_little_endian() noexcept {
        constexpr uint16_t test = 0x0001;
        return *reinterpret_cast<const uint8_t*>(&test) == 0x01;
    }
};

// Common aliases
using be16 = BigEndian<uint16_t>;
using be32 = BigEndian<uint32_t>;
using be64 = BigEndian<uint64_t>;

// Helper functions
template<typename T>
T load_be(const void* ptr) noexcept {
    return BigEndian<T>::load(ptr).to_host();
}

template<typename T>
void store_be(void* ptr, T value) noexcept {
    BigEndian<T> be(value);
    be.store(ptr);
}

} // namespace endian
} // namespace xe