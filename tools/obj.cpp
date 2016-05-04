#include <set>
#include <sstream>
#include <tuple>
#include <vector>

#include <cxx-prettyprint/prettyprint.hpp>
#include <tinyobjloader/tiny_obj_loader.h>

#include "cmd.h"

using namespace cmd;
using namespace std;
using namespace tinyobj;

typedef tuple<float, float, float> position;
typedef tuple<float, float, float> normal;
typedef tuple<float, float> texcoord;

typedef tuple<position, normal, texcoord> vertex;

int main(int argc, const char* argv[]) {
    cstr_flag infile("infile", ".obj file to parse");
    bool_flag list("list", "if set, print a list of objects to stderr");

    parse_args(argc, argv);

    vector<shape_t> shapes;
    vector<material_t> materials;

    string err;
    if (!LoadObj(shapes, materials, err, infile)) {
        error("Error reading .obj file: %s", err.c_str());
    }

    for (const shape_t& s : shapes) {
        const mesh_t& m = s.mesh;
        assert(m.positions.size() == m.indices.size() * 3);
        assert(m.normals.size() == m.indices.size() * 3);
        assert(m.texcoords.size() == m.indices.size() * 2);

        vector<vertex> vertices;
        for (int i = 0; i < m.indices.size(); ++i) {
            position p { m.positions[3*i], m.positions[3*i + 1], m.positions[3*i + 2] };
            normal n { m.normals[3*i], m.normals[3*i + 1], m.normals[3*i + 2] };
            texcoord t { m.texcoords[2*i], m.texcoords[2*i + 1] };

            vertex v { p, n, t };
            vertices.push_back(v);
        }

        set<vertex> unique;
        for (const vertex& v : vertices) {
            unique.insert(v);
        }

        if (list) {
            log("%s (%d indices, %d vertices)",
                s.name.c_str(), (int) vertices.size(), (int) unique.size());
            for (const vertex& v : unique) {
                stringstream buf;
                buf << v;
                vlog("    %s", buf.str().c_str());
            }
            vlog("");
        }
    }

    if (list) {
        log("%d shape%s", shapes.size(), shapes.empty() ? "" : "s");
    }

    vlog("Success!");
    return 0;
}
