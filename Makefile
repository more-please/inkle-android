# Note: on OS 10.9, this only works with Xcode 5. However, Apportable needs Xcode 4!
# Until they fix Apportable you'll need to switch back and forth via xcode-select.

CXX = clang++ -x c++ -O4 -I./3rd-party/src

COMMON_HEADERS = \
	tools/file_scanner.h \
	tools/package_writer.h \
	3rd-party/src/stb_image_write.h \
	3rd-party/src/stb_image.h \
	3rd-party/src/stb_truetype.h

COMMON_SRCS = \
	tools/file_scanner.cpp \
	tools/package_writer.cpp \
	3rd-party/src/stb_image_write.c \
	3rd-party/src/stb_image.c \
	3rd-party/src/stb_truetype.c

all: build/pak build/atlas build/superellipse build/fontex

build/pak: tools/pak.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	$(CXX) tools/pak.cpp $(COMMON_SRCS) -o build/pak

build/atlas: tools/atlas.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	$(CXX) tools/atlas.cpp $(COMMON_SRCS) -o build/atlas

build/superellipse: tools/superellipse.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	$(CXX) tools/superellipse.cpp $(COMMON_SRCS) -o build/superellipse

build/fontex: tools/fontex.cpp tools/fontex.h $(COMMON_SRCS) $(COMMON_HEADERS)
	$(CXX) tools/fontex.cpp $(COMMON_SRCS) -o build/fontex

clean:
	rm build/atlas
	rm build/pak
	rm build/superellipse
	rm build/fontex