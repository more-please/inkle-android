#include <assert.h>
#include <math.h>
#include <unistd.h>

#include <algorithm>
#include <iostream>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "file_scanner.h"
#include "package_writer.h"
#include "stb_image.h"
#include "stb_image_write.h"

using namespace std;

// Size of the atlas(es) that the input images will be rendered to.
const int ATLAS_SIZE = 2048;

// The atlas is divided into rows.
const int ROW_HEIGHT = 64;
const int ATLAS_ROWS = ATLAS_SIZE / ROW_HEIGHT;

// Width of tile border, to prevent cross-contamination. We need 2^N to support mipmap level N.
const int BORDER_SIZE = 4;
const int STEP_SIZE = BORDER_SIZE;

// Each image is divided into row-sized strips, with borders at top and bottom.
const int STRIP_HEIGHT = ROW_HEIGHT - 2 * BORDER_SIZE;

// Allow tiles to be marked entirely clear or entirely opaque if alpha is within this threshold.
// TODO: define MIN_ALPHA and MAX_ALPHA, stretch them out to the full 0-255 range.
// TODO: ...and if we do that we should probably also do Floyd-Steinberg dithering, I guess.
const int ALPHA_THRESHOLD = 7;

// Minimum size of a blank strip to break even (assuming it's between alpha strips).
const int MIN_CLEAR_WIDTH = 2 * BORDER_SIZE;

// Minimum size of a solid strip to break even (assuming it's between alpha strips).
const int MIN_SOLID_WIDTH = 4 * BORDER_SIZE;

// Number of rows in an atlas.

// Maximum total width of all strips in an atlas, including 4 borders per row to allow for splits.
const int ATLAS_MAX_TOTAL_WIDTH = ATLAS_ROWS * (ATLAS_SIZE - 4 * BORDER_SIZE);

string ANDROID_DIR = ".";

union Pixel {
    Pixel() : r(0), g(0), b(0), a(0) {}
    Pixel(unsigned char r, unsigned char g, unsigned char b, unsigned char a) : r(r), g(g), b(b), a(a) {}

    Pixel rgb() const {
        return Pixel(r, g, b, 255);
    }
    Pixel aaa() const {
        return Pixel(a, a, a, 255);
    }

    bool operator<(const Pixel& other) const {
        return r < other.r || g < other.g || b < other.b || a < other.a;
    }
    struct { unsigned char r, g, b, a; };
    unsigned char v[4];
};

class Image;

// A rectangular section of an Image, STRIP_HEIGHT pixels high.
class Strip {
public:
    Strip(const Image* image, bool isSolid, int x, int y, int width)
        : image(image), isSolid(isSolid), x(x), y(y), width(width) {
        assert(width % STEP_SIZE == 0);
    }

    pair<Strip, Strip> split(int splitWidth) const {
        return make_pair(
            Strip(image, isSolid, x, y, splitWidth),
            Strip(image, isSolid, x + splitWidth, y, width - splitWidth));
    }

    const Pixel& pixel(int xOffset, int yOffset) const;

    int isEmpty() const {
        return width <= 0;
    }

    int fullWidth() const {
        return width + 2 * BORDER_SIZE;
    }
    
    const Image* image;
    bool isSolid;
    int x, y, width;
};

// A PNG input file.
class Image {
public:
    Image(const string& base, const string& name)
        : base(base), name(name), solidWidth(0), alphaWidth(0)
    {
        string filename = base.empty() ? name : (base + "/" + name);
        int components;
        bytes = stbi_load(filename.c_str(), &width, &height, &components, 4);
        if (!bytes) {
            cerr << "Failed to load " << name << ": " << stbi_failure_reason() << endl;
            exit(EXIT_FAILURE);
        }
        for (int y = 0; y < height; y += STRIP_HEIGHT) {
            int x = 0;

            // Skip any number of clear pixels at the start of the row.
            while (x < width && isClear(x, y, 1)) {
                ++x;
            }
            
            while (x < width) {
                // Skip clear pixels if there are enough to break even.
                if (isClear(x, y, MIN_CLEAR_WIDTH)) {
                    x += MIN_CLEAR_WIDTH;
                    while (x < width && isClear(x, y, 1)) {
                        ++x;
                    }
                    continue;
                }

                // Create an opaque strip, if it's long enough to break even.
                if (isSolid(x, y, MIN_SOLID_WIDTH)) {
                    int xSolid = x;
                    x += MIN_SOLID_WIDTH;
                    while (x < width && isSolid(x, y, STEP_SIZE)) {
                        x += STEP_SIZE;
                    }
                    solidStrips.push_back(Strip(this, true, xSolid, y, x - xSolid));
                    solidWidth += (x - xSolid) + 2 * BORDER_SIZE;
                    continue;
                }

                // Otherwise, create an alpha-blended strip.
                int xAlpha = x;
                while (x < width && !isClear(x, y, MIN_CLEAR_WIDTH) && !isSolid(x, y, MIN_SOLID_WIDTH)) {
                    x += STEP_SIZE;
                }
                assert(x > xAlpha);
                alphaStrips.push_back(Strip(this, false, xAlpha, y, x - xAlpha));
                alphaWidth += (x - xAlpha) + 2 * BORDER_SIZE;
            }
        }
    }

    ~Image() {
        stbi_image_free(bytes);
    }

    const Pixel& pixel(int x, int y) const;

    string base, name;
    int width, height;
    unsigned char* bytes;
    vector<Strip> solidStrips;
    vector<Strip> alphaStrips;
    int solidWidth;
    int alphaWidth;

private:
    unsigned char isSolid(int x1, int y1, int width) const {
        const int x2 = x1 + width;
        const int y2 = y1 + STRIP_HEIGHT;
        unsigned char minAlpha = 255;
        for (int y = y1; y < y2; ++y) {
            for (int x = x1; x < x2; ++x) {
                const Pixel& p = pixel(x, y);
                minAlpha = min(minAlpha, p.a);
            }
        }
        return minAlpha >= (255 - ALPHA_THRESHOLD);
    }

    unsigned char isClear(int x1, int y1, int width) const {
        const int x2 = x1 + width;
        const int y2 = y1 + STRIP_HEIGHT;
        unsigned char maxAlpha = 0;
        for (int y = y1; y < y2; ++y) {
            for (int x = x1; x < x2; ++x) {
                const Pixel& p = pixel(x, y);
                maxAlpha = max(maxAlpha, p.a);
            }
        }
        return maxAlpha <= ALPHA_THRESHOLD;
    }
};

const Pixel& Strip::pixel(int xOffset, int yOffset) const {
    return image->pixel(x + xOffset, y + yOffset);
}

const Pixel& Image::pixel(int x, int y) const {
    // Clamp to edge
    x = max(0, min(x, width - 1));
    y = max(0, min(y, height - 1));
    return *(reinterpret_cast<Pixel*>(bytes + (y * width + x) * 4));
}

enum TextureFormat {
    FORMAT_IOS,
    FORMAT_ANDROID,
    FORMAT_PNG
};

// A texture output file, ATLAS_SIZE pixels in each dimension.
class Atlas {
public:
    Atlas() : totalWidth(0), rowsDirty(false) {}

    bool maybeAdd(shared_ptr<Image> image) {
        int imageWidth = image->solidWidth + 2 * image->alphaWidth;
        if (totalWidth + imageWidth <= ATLAS_MAX_TOTAL_WIDTH) {
            images.push_back(image);
            totalWidth += imageWidth;
            rowsDirty = true;
            return true;
        } else {
            return false;
        }
    }

    typedef vector<Strip> Row;

    Pixel& pixel(int x, int y) {
        return *reinterpret_cast<Pixel*>(&data[0] + 4 * (x + ATLAS_SIZE * y));
    }
    
    const Pixel& pixel(int x, int y) const {
        return *reinterpret_cast<const Pixel*>(&data[0] + 4 * (x + ATLAS_SIZE * y));
    }
    
    void writePng(const string& filename) {
        maybeAllocateRows();
        stbi_write_png(filename.c_str(), ATLAS_SIZE, ATLAS_SIZE, 4, &data[0], 4 * ATLAS_SIZE);
    }

    struct Header {
        uint16_t width;
        uint16_t height;
        uint16_t numAlpha;
        uint16_t numSolid;
    };

    struct Quad {
        uint16_t x, y;
        uint16_t xTex, yTex;
        uint16_t width, height;
    };

    void sys(const string& cmd) {
        cerr << cmd << endl;
        int status = system(cmd.c_str());
        assert(status == EXIT_SUCCESS);
    }

    void write(const string& outdir, const string& filename, TextureFormat format) {
        assert(sizeof(Header) == 8);
        assert(sizeof(Quad) == 12);

        maybeAllocateRows();

        // Write texture.
        char scratch[25] = "/tmp/ImageDicer.XXXXXXXX";
        mkdtemp(scratch);
        string tempDir(scratch);
        string tempFile = tempDir + "/" + filename;

        string pngFile = tempFile + ".png";
        cerr << "stbi_write_png " << pngFile << endl;
        stbi_write_png(pngFile.c_str(), ATLAS_SIZE, ATLAS_SIZE, 4, &data[0], ATLAS_SIZE * 4);

        string binDir = ANDROID_DIR + "/3rd-party/bin";
        string texFile, cmd;
        if (format == FORMAT_ANDROID) {
            // KTX format (Android)
            texFile = tempFile + ".ktx";
            sys("cd " + binDir + " && ./etcpack " + pngFile + " " + tempDir + " -c etc1 -mipmaps -ktx");
            sys("rm " + pngFile);
        } else if (format == FORMAT_IOS) {
            // PVR format (iOS)
            texFile = tempFile + ".pvr";
            string texturetool = binDir + "/texturetool";
            sys(texturetool + " -e PVRTC --channel-weighting-perceptual --bits-per-pixel-4 -f PVR -m -s -o " + texFile + " " + pngFile);
            sys("rm " + pngFile);
        } else if (format == FORMAT_PNG) {
            texFile = pngFile;
        } else {
            cerr << "Unknown texture format!" << endl;
            exit(EXIT_FAILURE);
        }

        sys("mkdir -p " + outdir);
        sys("mv " + texFile + " " + outdir);
        sys("rmdir " + tempDir);

        // Write images.
        for (int i = 0; i < images.size(); ++i) {
            Image& image = *images[i];
            vector<unsigned char> imageData(8); // 8 bytes for the header.

            int numAlpha = 0;
            int numSolid = 0;
            for (int yTex = 0; yTex < rows.size(); ++yTex) {
                Row& row = rows[yTex];
                int xTex = 0;
                for (Row::iterator iter = row.begin(); iter != row.end() ; ++iter) {
                    Strip& strip = *iter;
                    if (strip.image == &image) {
                        if (strip.isSolid) {
                            ++numSolid;
                        } else {
                            assert(numSolid == 0);
                            ++numAlpha;
                        }

                        // Write out the strip.
                        imageData.resize(imageData.size() + 12);
                        Quad& quad = *reinterpret_cast<Quad*>(&imageData[imageData.size() - 12]);
                        quad.x = strip.x;
                        quad.y = strip.y;
                        quad.xTex = xTex + BORDER_SIZE;
                        quad.yTex = (yTex * ROW_HEIGHT) + BORDER_SIZE;
                        quad.width = strip.width;
                        quad.height = min(STRIP_HEIGHT, image.height - strip.y);
                    }
                    xTex += strip.fullWidth();
                }
            }

            // Finish the header.
            Header& header = *reinterpret_cast<Header*>(&imageData[0]);
            header.width = image.width;
            header.height = image.height;
            header.numAlpha = numAlpha;
            header.numSolid = numSolid;

            // Add the texture filename.
            string basename = texFile.substr(1 + texFile.find_last_of("/"));
            const char* c = basename.c_str();
            imageData.insert(imageData.end(), c, c + strlen(c) + 1);

            // And we're done! Write it to disk.
            string path = outdir + "/" + image.name + ".img";
            FILE* f = fopen(path.c_str(), "wb");
            size_t written = fwrite(&imageData[0], 1, imageData.size(), f);
            assert(written == imageData.size());
            fclose(f);
        }
    }

    vector<shared_ptr<Image> > images;
    int totalWidth;
    bool rowsDirty;
    vector<Row> rows;
    vector<unsigned char> data;

private:
    void maybeAllocateRows() {
        if (!rowsDirty) {
            return;
        }
        rowsDirty = false;

        rows.clear();
        rows.resize(ATLAS_ROWS);

        // Keep it simple: process images in order, split across atlas row boundaries as needed.
        int row = 0;

        // Allocate alpha first as each strip needs twice as much space.
        int spaceInRow = ATLAS_SIZE / 2;

        for (int i = 0; i < images.size(); ++i) {
            Image& image = *images[i];
            for (int j = 0; j < image.alphaStrips.size(); ++j) {
                Strip strip = image.alphaStrips[j];
                assert(!strip.isSolid);
                while (strip.fullWidth() > spaceInRow) {
                    pair<Strip, Strip> p = strip.split(spaceInRow - 2 * BORDER_SIZE);
                    if (!p.first.isEmpty()) {
                        assert(row < ATLAS_ROWS);
                        rows[row].push_back(p.first);
                    }
                    ++row;
                    spaceInRow = ATLAS_SIZE / 2;
                    strip = p.second;
                }
                if (!strip.isEmpty()) {
                    assert(row < ATLAS_ROWS);
                    rows[row].push_back(strip);
                    assert(strip.fullWidth() <= spaceInRow);
                    spaceInRow -= strip.fullWidth();
                    if (spaceInRow <= 0) {
                        ++row;
                        spaceInRow = ATLAS_SIZE / 2;
                    }
                }
            }
        }

        // Now allocate solid strips.
        spaceInRow *= 2;

        for (int i = 0; i < images.size(); ++i) {
            Image& image = *images[i];
            for (int j = 0; j < image.solidStrips.size(); ++j) {
                Strip strip = image.solidStrips[j];
                assert(strip.isSolid);
                while (strip.fullWidth() > spaceInRow) {
                    pair<Strip, Strip> p = strip.split(spaceInRow - 2 * BORDER_SIZE);
                    if (!p.first.isEmpty()) {
                        rows[row].push_back(p.first);
                    }
                    assert(row < ATLAS_ROWS);
                    ++row;
                    spaceInRow = ATLAS_SIZE;
                    strip = p.second;
                }
                if (!strip.isEmpty()) {
                    assert(row < ATLAS_ROWS);
                    rows[row].push_back(strip);
                    assert(strip.fullWidth() <= spaceInRow);
                    spaceInRow -= strip.fullWidth();
                    if (spaceInRow <= 0) {
                        ++row;
                        spaceInRow = ATLAS_SIZE;
                    }
                }
            }
        }

        // Render the atlas.
        data.resize(ATLAS_SIZE * ATLAS_SIZE * 4);
        for (int i = 0; i < rows.size(); ++i) {
            const Row& row = rows[i];
            int yTop = i * ROW_HEIGHT;
            assert(yTop < ATLAS_SIZE);
            int xLeft = 0;
            for (int j = 0; j < row.size(); ++j) {
                const Strip& strip = row[j];
                int xRight = ATLAS_SIZE - xLeft;
                assert(strip.isSolid || xLeft < xRight);
                for (int y = 0; y < ROW_HEIGHT; ++y) {
                    for (int x = 0; x < (strip.width + 2 * BORDER_SIZE); ++x) {
                        Pixel p = strip.pixel(x - BORDER_SIZE, y - BORDER_SIZE);
#if 0 // Blue glow around each strip, for visual debugging
                        if (x < BORDER_SIZE || x >= (strip.fullWidth() - BORDER_SIZE) || y < BORDER_SIZE || y > (ROW_HEIGHT - BORDER_SIZE)) {
                            p.b = 0.5 * (p.b + 255);
                        }
#endif
                        pixel(xLeft + x, yTop + y) = p.rgb();
                        if (!strip.isSolid) {
                            pixel(xRight - x - 1, yTop + y) = p.aaa();
                        }
                    }
                }
                xLeft += strip.fullWidth();
            }
        }
    }
};

ostream& operator<<(ostream& o, const Image& image) {
    return o << "Image(" << image.name << ", " << image.width << ", " << image.height << ")";
}

ostream& operator<<(ostream& o, const Strip& strip) {
    o << "Strip(" << strip.image->name << ", " << strip.x << ", " << strip.y << ", " << strip.width;
    o << (strip.isSolid ? ", solid" : ", alpha");
    return o << ")";
}

ostream& operator<<(ostream& o, const Atlas& atlas) {
    double percentFull = 100 * double(atlas.totalWidth) / ATLAS_MAX_TOTAL_WIDTH;
    o << "Atlas(" << atlas.images.size() << " images, " << percentFull << "% full)" << endl;
    return o;
}

class ImageSlicer {
public:
    ImageSlicer() : goodPixels(0), badPixels(0) {}

    void maybeAddImage(const string& base, const string& name) {
        const char* suffix = name.c_str();
        for (const char* c = suffix; *c; ++c) {
            if (*c == '.') {
                suffix = c;
            }
        }
        const char* known[] = {
            ".png", ".jpg", ".jpeg", ".gif", NULL
        };
        for (int i = 0; known[i]; ++i) {
            if (strncmp(suffix, known[i], strlen(known[i])) == 0) {
                addImage(base, name);
                return;
            }
        }
    }

    void addImage(const string& base, const string& name) {
        shared_ptr<Image> image(new Image(base, name));
        for (int i = 0; i < atlases.size(); ++i) {
            if (atlases[i].maybeAdd(image)) {
                goodPixels += image->width * image->height;
                return;
            }
        }
        atlases.push_back(Atlas());
        if (atlases.back().maybeAdd(image)) {
            goodPixels += image->width * image->height;
        } else {
            cerr << "*** " << *image << " is too big for any atlas, skipping" << endl;
            badPixels += image->width * image->height;
            atlases.erase(atlases.end() - 1);
        }
    }

    void dump() {
        cerr << endl;
        cerr << atlases.size() << " atlases:" << endl;
        for (int i = 0; i < atlases.size(); ++i) {
            cerr << "  " << atlases[i] << endl;
            for (int j = 0; j < atlases[i].images.size(); ++j) {
                cerr << "    " << *(atlases[i].images[j]) << endl;
            }
        }
        cerr << endl;

        long outPixels = atlases.size() * ATLAS_SIZE * ATLAS_SIZE;
        cerr << "Input size:  " << goodPixels << " pixels" << endl;
        cerr << "Output size: " << outPixels << " pixels" << endl;
        cerr << "Change: " << 100 * (outPixels / double(goodPixels) - 1) << "%" << endl;
        cerr << "Discarded: " << badPixels << " pixels (" << 100 * (badPixels / double(goodPixels + badPixels)) << "%)" << endl;
        cerr << endl;
    }

    void writeAtlases(const string& outdir, TextureFormat format) {
        for (int i = 0; i < atlases.size(); ++i) {
            string filename = "img_atlas_" + to_string(i);
            cerr << "Writing " << filename << endl;
//            atlases[i].writePng(filename + ".png");
            atlases[i].write(outdir, filename, format);
        }
    }

private:
    int goodPixels;
    int badPixels;
    vector<Atlas> atlases;
};

void usage() {
    cerr << "Packs multiple images into a set of .img files and textures." << endl;
    cerr << "The output is written to a .pak file." << endl;
    cerr << "All specified files and directories are added." << endl << endl;
    cerr << "Usage: atlas -d outdir -t ios|android|png [-i glob] [-x glob] paths..." << endl;
    cerr << "  -d, --outdir: output directory (required)" << endl;
    cerr << "  -t, --texture: 'ios' or 'android' (required)" << endl;
    cerr << "  -i, --include: glob for files to include (optional)" << endl;
    cerr << "  -x, --exclude: glob for files to exclude (optional)" << endl;
    cerr << "  -v, --verbose: list skipped files as well as added files" << endl;
    cerr << "  -h, --help: show this help text" << endl << endl;
    flush(cerr);
    exit(1);
}

int main(int argc, const char* argv[]) {
    ANDROID_DIR = argv[0];
    for (int i = ANDROID_DIR.size() - 1; i >= 0; --i) {
        if (ANDROID_DIR[i] == '/') {
            ANDROID_DIR = ANDROID_DIR.substr(0, i);
            break;
        }
    }
    ANDROID_DIR = ANDROID_DIR + "/../..";

    bool verbose = false;
    string formatStr;
    string outdir;
    vector<string> paths;
    vector<string> includes;
    vector<string> excludes;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "-v" || arg == "--verbose") {
            verbose = true;
        } else if (arg == "-h" || arg == "--help") {
            usage();
        } else if (arg[0] == '-') {
            if ((i+1) >= argc) {
                cerr << "Missing argument for " << arg << endl << endl;
                usage();
            }
            string param = argv[++i];
            if (param.empty()) {
                cerr << "Missing argument for " << arg << endl << endl;
                usage();
            }            
            if (arg == "-d" || arg == "--outdir") {
                if (!outdir.empty()) {
                    usage();
                }
                outdir = param;
            } else if (arg == "-i" || arg == "--include") {
                includes.push_back(param);
            } else if (arg == "-x" || arg == "--exclude") {
                excludes.push_back(param);
            } else if (arg == "-t" || arg == "--texture") {
                formatStr = param;
            } else {
                cerr << "Unknown flag: " << arg << endl << endl;
                usage();
            }
        } else {
            paths.push_back(arg);
        }
    }

    if (outdir.empty()) {
        cerr << "No output file specified! (use -d or --outdir)" << endl << endl;
        usage();
    }
    
    TextureFormat format;
    if (formatStr == "ios") {
        format = FORMAT_IOS;
    } else if (formatStr == "android") {
        format = FORMAT_ANDROID;
    } else if (formatStr == "png") {
        format = FORMAT_PNG;
    } else {
        cerr << "No texture format specified! (use -t ios, -t android or -t png)" << endl << endl;
        usage();
    }
    
    if (paths.empty()) {
        cerr << "No input files specified!" << endl << endl;
        usage();
    }

    excludes.push_back(outdir);

    FileScanner scanner(includes, excludes);
    scanner.verbose = verbose;
    scanner.stripDirectories = true;
    for (vector<string>::iterator i = paths.begin(); i != paths.end(); ++i) {
        scanner.addFileOrDir(*i, "");
    }
    set<FileScanner::base_name> files = scanner.getFiles();

    ImageSlicer slicer;
    for (set<FileScanner::base_name>::iterator i = files.begin(); i != files.end(); ++i) {
        const string& base = i->first;
        const string& name = i->second;
        slicer.maybeAddImage(base, name);
    }

    if (verbose) {
        slicer.dump();
    }

    slicer.writeAtlases(outdir, format);
}
