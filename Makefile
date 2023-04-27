# Disable built-in rules and variables. Sanity please!
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
.SUFFIXES:

TARGETS = \
	bin/fontex \
	bin/pak \
	bin/pak_crc \
	bin/png2ktx \
	bin/power_of_two \
	bin/repak \
	bin/rgbk \
	bin/round_corners \
	bin/swizzle \
	bin/trim \
	bin/xor

CXX = \
	clang++ -std=c++11 -Ofast -x c++ \
	-Wno-deprecated-declarations \
	-I include \
	-I 3rd-party/json-parser \
	-I 3rd-party/stb \
	-I 3rd-party/imgtec.com \
	lib/*.cpp \
	3rd-party/stb/*.c \
	3rd-party/json-parser/*.c \
	-lz

all : ${TARGETS}

bin/% : tools/%.cpp
	${CXX} $< -o $@

.PHONY : clean

clean :
	rm -f ${TARGETS}
