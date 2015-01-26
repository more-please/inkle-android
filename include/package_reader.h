#pragma once

#include <map>
#include <string>
#include <vector>

class PackageReader {
public:
    PackageReader() {}
    explicit PackageReader(const std::string& filename);

    void add(const PackageReader&);
    void subtract(const PackageReader&);

    void add(const std::string& name, const std::vector<char>& data);
    void subtract(const std::string& name, const std::vector<char>& data);

    bool has(const std::string& name) const {
        return _data.find(name) != _data.end();
    }

    const std::vector<char>& get(const std::string& name) const {
        return _data.find(name)->second;
    }

    const std::map<std::string, std::vector<char>> data() const {
        return _data;
    }

private:
    std::map<std::string, std::vector<char>> _data;
};
