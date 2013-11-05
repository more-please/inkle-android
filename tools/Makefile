CXX = clang++ -x c++ -idirafter ../3rd-party

COMMON_HEADERS = \
	file_scanner.h \
	package_writer.h \
	../3rd-party/stb_image_write.h \
	../3rd-party/stb_image.h

COMMON_SRCS = \
	file_scanner.cpp \
	package_writer.cpp \
	../3rd-party/stb_image_write.c \
	../3rd-party/stb_image.c

all: pak atlas

pak: pak.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	$(CXX) pak.cpp $(COMMON_SRCS) -o pak

atlas: atlas.cpp $(COMMON_SRCS) $(COMMON_HEADERS)
	$(CXX) atlas.cpp $(COMMON_SRCS) -o atlas

clean:
	rm pak
