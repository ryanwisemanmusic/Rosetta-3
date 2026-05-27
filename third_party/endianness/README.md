# Endianness

Endianness is very simple, light, header-only library designed to reduce conversions between big-endian and little-endian data.
* **Requires STL C++17**

### Build and Install
#### Usage after install
Endianness library can be built and installed as any other cmake project. After that add to your CMake project file `CMakeLists.txt`:
```cmake
find_package(Endianness)
```
And [link](https://cmake.org/cmake/help/latest/command/target_link_libraries.html) to your target [imported target](https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html#imported-targets) `ENDIAN::Endian` 
```
target_link_libraries(<target> ENDIAN::Endian)
```
#### Usage as submodule
If you prefer submodule instead of install add to your `CMakeLists.txt`
```cmake
add_subdirectory(<Endianness source realative path>)
target_link_libraries(<target> ENDIAN::Endian)
```

### Debug Visualisation

With happy debugging on MSVS you can use [Endian.natvis](https://github.com/aleksey-nikolaev/natvis-collection/blob/master/Endian.natvis)
This `natvis` file can swap bytes of big-endian data for better view.

### Usage

* You can use the `Endian` in `constexpr`
* It is possible to use the `Endian` as a key in [unordered associative containers](https://en.cppreference.com/w/cpp/container). Avoid to use with containers that need the less operator for comparision - only `==` and `!=` operators have no byte swap.
* Not necessary, but useful aliases:
```cpp
#include <endianness.h>
#include <stdint.h>

using int16le = endianness::LittleEndian<int16_t>;
using uint16le = endianness::LittleEndian<uint16_t>;
using int32le = endianness::LittleEndian<int32_t>;
using uint32le = endianness::LittleEndian<uint32_t>;
using int64le = endianness::LittleEndian<int64_t>;
using uint64le = endianness::LittleEndian<uint64_t>;

using int16be = endianness::BigEndian<int16_t>;
using uint16be = endianness::BigEndian<uint16_t>;
using int32be = endianness::BigEndian<int32_t>;
using uint32be = endianness::BigEndian<uint32_t>;
using int64be = endianness::BigEndian<int64_t>;
using uint64be = endianness::BigEndian<uint64_t>;
```
### Example
* No byte swap type conversion:
```cpp
constexpr uint32be MASK = 0xF0F01234; //Compile-time expressions
#pragma pack(push, 1)
struct FileHeader
{
    static constexpr uint32be SIGNATURE = 'A123'; //Compile-time expressions
    uint32be signature;
    uint32be tag; 
};
#pragma pop()
...
std::unordered_set<uint32be> tags{'qwer','tyui','opas','dfgh'};
std::unordered_map<uint32be, int> hashmap;
auto fileHeader = reinterpret_cast<const FileHeader*>(pointer);
if (fileHeader && fileHeader->signature == FileHeader::SIGNATURE){
  uint32be tag = fileHeader->tag;
  if(tags.count(tag)){
    tag &= MASK;
    ++hashmap[tag];
  }
}
```
* With byte swap:
```cpp
// no byte swap on big-endian platform
uint16be a = 7;
uint32be b = a;// uint16be -> uint16_t -> uint32_t -> uint32be
int c = a + b;
bool d = (a < 32) // ok: uint16be -> uint16_t : d = true
//bool e = (a != 3) // error: need explicitly cast a to int or 3 to uint16be
bool e = (a != (uint16be)3) // ok: e = true
```