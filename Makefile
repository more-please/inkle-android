# Note: on OS 10.9, this only works with Xcode 5. However, Apportable needs Xcode 4!
# Until they fix Apportable you'll need to switch back and forth via xcode-select.

# Is this the world's worst makefile? Oh, come on, who needs separate compilation...

CXX = clang++ -x c++ -O3 -std=c++11 -I./3rd-party/stb -I./3rd-party/imgtec.com

COMMON_HEADERS = \
	tools/file_scanner.h \
	tools/fix_alpha.h \
	tools/read_entire_file.h \
	3rd-party/stb/stb_image.h \
	3rd-party/stb/stb_image_resize.h \
	3rd-party/stb/stb_image_write.h \
	3rd-party/stb/stb_truetype.h

COMMON_SRCS = \
	tools/file_scanner.cpp \
	3rd-party/stb/stb_image.c \
	3rd-party/stb/stb_image_resize.c \
	3rd-party/stb/stb_image_write.c \
	3rd-party/stb/stb_truetype.c

all: \
		build/bin/pak \
		build/bin/repak \
		build/bin/atlas \
		build/bin/superellipse \
		build/bin/fontex \
		build/bin/split \
		build/bin/tippex \
		build/bin/bbox \
		build/bin/png2ktx \
		build/bin/pvr2png \
		build/bin/swizzle \
		build/bin/separate_alpha \
		build/bin/power_of_two \
		build/bin/rotate

build/bin/pak: tools/pak.cpp tools/package_writer.cpp tools/package_writer.h $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/pak.cpp tools/package_writer.cpp $(COMMON_SRCS) -lz -o build/bin/pak

build/bin/repak: tools/repak.cpp \
		tools/package_reader.cpp tools/package_reader.h \
		tools/package_writer.cpp tools/package_writer.h \
		$(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/repak.cpp \
		tools/package_reader.cpp \
		tools/package_writer.cpp \
		$(COMMON_SRCS) -lz -o build/bin/repak

build/bin/atlas: tools/atlas.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/atlas.cpp $(COMMON_SRCS) -o build/bin/atlas

build/bin/superellipse: tools/superellipse.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/superellipse.cpp $(COMMON_SRCS) -o build/bin/superellipse

build/bin/fontex: tools/fontex.cpp tools/fontex.h $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/fontex.cpp $(COMMON_SRCS) -o build/bin/fontex

build/bin/split: tools/split.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/split.cpp $(COMMON_SRCS) -o build/bin/split

build/bin/tippex: tools/tippex.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/tippex.cpp $(COMMON_SRCS) -o build/bin/tippex

build/bin/bbox: tools/bbox.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/bbox.cpp $(COMMON_SRCS) -o build/bin/bbox

build/bin/png2ktx: tools/png2ktx.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/png2ktx.cpp $(COMMON_SRCS) -o build/bin/png2ktx

build/bin/pvr2png: tools/pvr2png.cpp \
		3rd-party/imgtec.com/PVRTDecompress.cpp \
		3rd-party/imgtec.com/PVRTDecompress.h \
		$(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/pvr2png.cpp 3rd-party/imgtec.com/PVRTDecompress.cpp $(COMMON_SRCS) -o build/bin/pvr2png

build/bin/swizzle: tools/swizzle.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/swizzle.cpp $(COMMON_SRCS) -o build/bin/swizzle

build/bin/separate_alpha: tools/separate_alpha.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/separate_alpha.cpp $(COMMON_SRCS) -o build/bin/separate_alpha

build/bin/power_of_two: tools/power_of_two.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/power_of_two.cpp $(COMMON_SRCS) -o build/bin/power_of_two

build/bin/rotate: tools/rotate.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/rotate.cpp $(COMMON_SRCS) -o build/bin/rotate

clean:
	rm build/bin/*
