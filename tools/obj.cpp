#include <array>
#include <map>
#include <set>
#include <sstream>
#include <tuple>
#include <vector>

#include <cxx-prettyprint/prettyprint.hpp>
#include <tinyobjloader/tiny_obj_loader.h>

#define MINIZ_HEADER_FILE_ONLY
#include <miniz/miniz.c>

#include <more-cpp/please.h>

using namespace more::please;
using namespace std;
using namespace tinyobj;

typedef array<float, 3> position;
typedef array<float, 3> normal;
typedef array<float, 2> texcoord;

typedef tuple<position, normal, texcoord> vertex;

int main(int argc, const char* argv[]) {
    cstr_flag infile("infile", ".obj file to parse");
    cstr_flag outfile("outfile", "Path for output .zip file", NULL);
    bool_flag list("list", "if set, print a list of objects to stderr");
    int_flag<0, 9> compression("compression", "miniz compression level (0-9)", MZ_DEFAULT_LEVEL);

    parse_args(argc, argv);

    vector<shape_t> shapes;
    vector<material_t> materials;

    string err;
    if (!LoadObj(shapes, materials, err, infile)) {
        error("Error reading .obj file: %s", err.c_str());
    }

    mz_zip_archive zip {};
    if (outfile) {
        if (!mz_zip_writer_init_heap(&zip, 0, MZ_ZIP_MAX_IO_BUF_SIZE)) {
            error("mz_zip_writer_init_heap failed");
        }
    }

    for (const shape_t& s : shapes) {
        const char* name = s.name.c_str();
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

        map<vertex, int> unique;
        for (const vertex& v : vertices) {
            unique[v] = -1;
        }
        int next_index = 0;
        for (const vertex& v : vertices) {
            int& i = unique[v];
            if (i < 0) {
                i = next_index++;
            }
        }

        if (list) {
            log("%s (%d indices, %d vertices)",
                name, (int) vertices.size(), (int) unique.size());
            for (auto& entry : unique) {
                stringstream buf;
                buf << entry.first;
                vlog("    %s", buf.str().c_str());
            }
            vlog("");
        }

        if (outfile) {
            vlog("Building %s.index", name);

            string index_name = s.name + ".index";
            vector<uint16_t> index_data;
            for (unsigned int original_index : m.indices) {
                const vertex& v = vertices[original_index];
                int ix = unique[v];
                assert(ix >= 0);
                index_data.push_back(unique[v]);
            }
            mz_zip_writer_add_mem(
                &zip,
                index_name.c_str(),
                &index_data[0],
                index_data.size() * sizeof(index_data[0]),
                compression);
        }

        if (outfile) {
            vlog("Building %s.vertex", name);

            string vertex_name = s.name + ".vertex";
            vector<float> vertex_data;
            for (auto entry : unique) {
                const vertex& v = entry.first;
                vertex_data.insert(vertex_data.end(), get<0>(v).begin(), get<0>(v).end());
                vertex_data.insert(vertex_data.end(), get<1>(v).begin(), get<1>(v).end());
                vertex_data.insert(vertex_data.end(), get<2>(v).begin(), get<2>(v).end());
            }
            assert(vertex_data.size() == unique.size() * 8);

            mz_zip_writer_add_mem(
                &zip,
                vertex_name.c_str(),
                &vertex_data[0],
                vertex_data.size() * sizeof(vertex_data[0]),
                compression);
        }
    }

    if (list) {
        log("%d shape%s", (int) shapes.size(), shapes.empty() ? "" : "s");
    }

    if (outfile) {
        void* ptr;
        size_t size;
        if (!mz_zip_writer_finalize_heap_archive(&zip, &ptr, &size)) {
            error("mz_zip_writer_finalize_heap_archive failed");
        }

        vlog("Writing %s", outfile.get());
        FILE* f = fopen(outfile, "wb");
        int written = fwrite(ptr, 1, size, f);
        fclose(f);

        if (written < size) {
            error("fwrite failed - wrote %d bytes out of %d", (int) written, (int) size);
        }

        mz_zip_writer_end(&zip);
    }

    vlog("Success!");
    return 0;
}
