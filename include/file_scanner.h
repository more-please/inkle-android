#pragma once

#include <set>
#include <string>
#include <vector>

class FileScanner {
public:
    bool verbose {};
    bool stripDirectories {};

    FileScanner(const std::vector<std::string>& includes, const std::vector<std::string>& excludes)
        : _includes(includes)
        , _excludes(excludes)
    {}

    typedef std::pair<std::string, std::string> base_name;

    void addFileOrDir(const std::string& base, const std::string& name);

    std::set<base_name> getFiles() const {
        return _files;
    }

private:
    void addDir(const std::string& base, const std::string& name);
    void addFile(const std::string& base, const std::string& name);

    std::vector<std::string> _includes;
    std::vector<std::string> _excludes;
    std::set<base_name> _files;
};
