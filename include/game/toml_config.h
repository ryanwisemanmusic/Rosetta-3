#ifndef ROSETTA3_GAME_TOML_CONFIG_H
#define ROSETTA3_GAME_TOML_CONFIG_H

#include <cstdlib>
#include <fstream>
#include <string>
#include <unordered_map>

class TomlConfig {
public:
    bool load(const std::string &path)
    {
        std::ifstream file(path);
        if (!file.is_open()) return false;

        data_.clear();
        std::string current_section;
        std::string line;

        while (std::getline(file, line)) {
            size_t start = line.find_first_not_of(" \t\r");
            if (start == std::string::npos) continue;
            if (line[start] == '#') continue;

            if (line[start] == '[') {
                size_t end = line.find(']', start);
                if (end == std::string::npos) continue;
                current_section = line.substr(start + 1, end - start - 1);
                size_t s = current_section.find_first_not_of(" \t");
                size_t e = current_section.find_last_not_of(" \t");
                if (s != std::string::npos && e != std::string::npos)
                    current_section = current_section.substr(s, e - s + 1);
                continue;
            }

            size_t eq = line.find('=', start);
            if (eq == std::string::npos) continue;

            std::string key = line.substr(start, eq - start);
            size_t k_end = key.find_last_not_of(" \t");
            if (k_end != std::string::npos) key = key.substr(0, k_end + 1);

            std::string val_str = line.substr(eq + 1);
            size_t v_start = val_str.find_first_not_of(" \t");
            size_t v_end = val_str.find_last_not_of(" \t\r");

            Value val;
            val.type = Value::STRING;
            val.int_val = 0;

            if (v_start != std::string::npos && v_end != std::string::npos) {
                std::string trimmed = val_str.substr(v_start, v_end - v_start + 1);
                if (trimmed[0] == '"') {
                    size_t close = trimmed.find('"', 1);
                    if (close != std::string::npos)
                        val.string_val = trimmed.substr(1, close - 1);
                } else {
                    val.type = Value::INTEGER;
                    val.int_val = std::atoll(trimmed.c_str());
                }
            }

            data_[current_section][key] = val;
        }

        return true;
    }

    std::string get_string(const std::string &section,
                           const std::string &key,
                           const std::string &default_val) const
    {
        auto sec = data_.find(section);
        if (sec == data_.end()) return default_val;
        auto it = sec->second.find(key);
        if (it == sec->second.end()) return default_val;
        return it->second.string_val;
    }

    int64_t get_int(const std::string &section,
                    const std::string &key,
                    int64_t default_val) const
    {
        auto sec = data_.find(section);
        if (sec == data_.end()) return default_val;
        auto it = sec->second.find(key);
        if (it == sec->second.end()) return default_val;
        if (it->second.type != Value::INTEGER) return default_val;
        return it->second.int_val;
    }

private:
    struct Value {
        enum Type { STRING, INTEGER } type;
        std::string string_val;
        int64_t int_val;
    };

    std::unordered_map<std::string,
        std::unordered_map<std::string, Value>> data_;
};

#endif
