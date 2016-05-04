#pragma once

#include <assert.h>
#include <stdio.h>

#include <algorithm>
#include <string>
#include <vector>

namespace cmd {

inline int& _error_count() {
    static int _count = 0;
    return _count;
}

inline int& _error_guard() {
    static int _guard = 0;
    return _guard;
}

inline void error(const char* format, ...) {
    va_list args;
    va_start(args, format);
    fprintf(stderr, "*** ");
    vfprintf(stderr, format, args);
    fprintf(stderr, "\n");
    va_end(args);

    _error_count() += 1;
    if (_error_guard() == 0) {
        exit(1);
    }
}

inline bool valid() {
    return _error_count() == 0;
}

class handler {
public:
    explicit handler(const char* name) : _name(name) {}
    virtual ~handler() {}

    const char* name() const { return _name; }

    virtual int handle(int argc, const char* argv[]) = 0;
    virtual void print_help(FILE*) const = 0;

    virtual bool valid() const {
        return true;
    }

private:
    const char* _name;
};

class handler_list {
public:
    static const std::vector<handler*>& get() {
        return list();
    }

    static void add(handler* h) {
        list().push_back(h);
    }

    static void remove(handler* h) {
        list().erase(
            std::remove(list().begin(), list().end(), h),
            list().end());
    }

private:
    static std::vector<handler*>& list() {
        static handler_list _singleton;
        return _singleton._list;
    }

    handler_list() {}
    ~handler_list() {}

    std::vector<handler*> _list;
};

class base_flag : public handler {
public:
    virtual void print_help(FILE* f) const {
        fprintf(f, "%s", _help);
    }

protected:
    base_flag(const char* name, const char* help) : handler(name), _help(help) {
        handler_list::add(this);
    }

    ~base_flag() {
        handler_list::remove(this);
    }

private:
    const char* _help;
};

class bool_flag : public base_flag {
public:
    bool_flag(const char* name, const char* help) : base_flag(name, help) {}

    bool get() const {
        return _value;
    }

    operator bool() const {
        return get();
    }

protected:
    virtual int handle(int argc, const char* argv[]) {
        _value = true;
        return 1;
    }

private:
    bool _value = false;
};

template <typename T> class value_flag : public base_flag {
public:
    typedef T value_t;

    const value_t& get() const {
        if (!valid()) {
            error("--%s flag is required", name());
            exit(EXIT_FAILURE);
        }
        return _value;
    }

    operator value_t() const {
        return get();
    }

    virtual bool valid() const {
        return !_required || _inited;
    }

    virtual void print_help(FILE* f) const {
        base_flag::print_help(f);

        if (_required) {
            fprintf(f, " (required)");
        } else {
            fprintf(f, " (default: ");
            print(f, _value);
            fprintf(f, ")");
        }
    }

protected:
    value_flag(const char* name, const char* help)
        : base_flag(name, help)
        , _required(true) {}

    value_flag(const char* name, const char* help, const T& default_value)
        : base_flag(name, help)
        , _required(false)
        , _value(default_value) {}

    void init(const T& value) {
        if (_inited) {
            error("--%s flag can't be set multiple times", name());
            exit(EXIT_FAILURE);
        }
        _inited = true;
        _value = value;
    }

    virtual int handle(int argc, const char* argv[]) {
        if (argc < 2) {
            return 0;
        }
        const char* arg = argv[1];
        if (!parse(arg)) {
            error("Can't parse --%s flag: %s", name(), arg);
            return 0;
        }
        return 2;
    }

    virtual bool parse(const char*) = 0;
    virtual void print(FILE*, const value_t&) const = 0;

private:
    const bool _required;
    bool _inited = false;
    value_t _value {};
};

class cstr_flag : public value_flag<const char*> {
public:
    cstr_flag(const char* name, const char* help)
        : value_flag(name, help) {}

    cstr_flag(const char* name, const char* help, const char* default_value)
        : value_flag(name, help, default_value) {}

    virtual bool parse(const char* str) {
        init(str);
        return str;
    }

    virtual void print(FILE* f, const value_t& value) const {
        fprintf(f, "%s", value);
    }
};

class fopen_r_flag : public value_flag<FILE*> {
public:
    fopen_r_flag(const char* name, const char* help)
        : value_flag(name, help) {}

    fopen_r_flag(const char* name, const char* help, FILE* default_value)
        : value_flag(name, help, default_value) {}

    ~fopen_r_flag() {
        if (valid() && get()) {
            fclose(get());
        }
    }

    virtual bool parse(const char* str) {
        if (str) {
            FILE* f = fopen(str, "rb");
            if (f) {
                init(f);
                return true;
            }
        }
        return false;
    }

    virtual void print(FILE* f, const value_t& value) const {
        if (value == stdin) {
            fprintf(f, "stdin");
        } else if (!value) {
            fprintf(f, "none");
        } else {
            fprintf(f, "FILE*");
        }
    }
};

class fopen_w_flag : public value_flag<FILE*> {
public:
    fopen_w_flag(const char* name, const char* help)
        : value_flag(name, help) {}

    fopen_w_flag(const char* name, const char* help, FILE* default_value)
        : value_flag(name, help, default_value) {}

    ~fopen_w_flag() {
        if (valid() && get()) {
            fclose(get());
        }
    }

    virtual bool parse(const char* str) {
        if (str) {
            FILE* f = fopen(str, "rb");
            if (f) {
                init(f);
                return true;
            }
        }
        return false;
    }

    virtual void print(FILE* f, const value_t& value) const {
        if (value == stdout) {
            fprintf(f, "stdout");
        } else if (value == stderr) {
            fprintf(f, "stderr");
        } else if (!value) {
            fprintf(f, "none");
        } else {
            fprintf(f, "FILE*");
        }
    }
};

inline void print_help(FILE* f) {
    fprintf(f, "Command-line flags:\n");
    for (handler* h : handler_list::get()) {
        fprintf(f, "    --%s: ", h->name());
        h->print_help(f);
        fprintf(f, "\n");
    }
    fprintf(f, "\n");
}

inline bool starts_with(const char* a, const char* b) {
    assert(a && b);
    while (*a && (*a == *b)) {
        ++a, ++b;
    }
    return *b == 0;
}

inline int parse_one_arg(int argc, const char* argv[]) {
    assert(argc > 0);
    const char* arg = argv[0];

    // Require at least one '-'
    if (!arg || arg[0] != '-') {
        error("Expected a command-line flag, but found: %s", arg);
        return 0;
    }

    // Skip '-' characters
    while (*arg == '-') {
        ++arg;
    }

    // Gather handlers that match this flag
    std::vector<handler*> matches;
    for (handler* h : handler_list::get()) {
        if (starts_with(h->name(), arg)) {
            matches.push_back(h);
        }
    }

    // Require at least one match
    if (matches.empty()) {
        error("Unknown command-line flag: %s", argv[0]);
        return 0;
    }

    if (matches.size() > 1) {
        error("Ambiguous command-line flag: %s", argv[0]);
        error("Could match:");
        for (handler* h : matches) {
            error("    --%s", h->name());
        }
        return 0;
    }

    return matches[0]->handle(argc, argv);
}

inline bool verbose() {
    static bool_flag verbose_flag("verbose", "if set, use verbose output");
    return verbose_flag.get();
}

inline void vlog(const char* format, ...) {
    if (verbose()) {
        va_list args;
        va_start(args, format);
        vfprintf(stderr, format, args);
        fprintf(stderr, "\n");
        va_end(args);
    }
}

inline void log(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    fprintf(stderr, "\n");
    va_end(args);
}

struct scoped_error_guard {
    scoped_error_guard() {
        _error_guard() += 1;
    }
    ~scoped_error_guard() {
        int& guard = _error_guard();
        int& count = _error_count();
        --guard;
        if (guard == 0 && count > 0) {
            fprintf(stderr, "\n");
            print_help(stderr);
            exit(1);
        }
    }
};

inline int parse_args(int argc, const char* argv[]) {
    scoped_error_guard guard;

    if (argc < 1) {
        error("Expected at least 1 argument");
    }

    // Register shared global flags
    verbose();

    class help_flag : base_flag {
    public:
        help_flag() : base_flag("help", "Print this help information") {}

        int handle(int argc, const char* argv[]) {
            cmd::print_help(stdout);
            exit(0);
        }
    } help;

    int i = 1;
    while (valid() && i < argc) {
        i += parse_one_arg(argc - i, argv + i);
    }

    if (valid()) {
        for (handler* h : handler_list::get()) {
            if (!h->valid()) {
                error("--%s flag is required", h->name());
            }
        }
    }

    return i;
}

} // namespace flags
