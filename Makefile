# Note: on OS 10.9, this only works with Xcode 5. However, Apportable needs Xcode 4!
# Until they fix Apportable you'll need to switch back and forth via xcode-select.

# Is this the world's worst makefile? Oh, come on, who needs separate compilation...

CXX = clang++ -x c++ -O3 -I./3rd-party/stb

COMMON_HEADERS = \
	tools/file_scanner.h \
	tools/package_writer.h \
	3rd-party/stb/stb_image_write.h \
	3rd-party/stb/stb_image.h \
	3rd-party/stb/stb_truetype.h

COMMON_SRCS = \
	tools/file_scanner.cpp \
	tools/package_writer.cpp \
	3rd-party/stb/stb_image_write.c \
	3rd-party/stb/stb_image.c \
	3rd-party/stb/stb_truetype.c

all: build/bin/pak build/bin/atlas build/bin/superellipse build/bin/fontex build/bin/split build/bin/tippex

build/bin/pak: tools/pak.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	mkdir -p build/bin
	$(CXX) tools/pak.cpp $(COMMON_SRCS) -o build/bin/pak

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

clean:
	rm build/bin/*
