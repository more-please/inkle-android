cmake_minimum_required(VERSION 2.4)

project(
    more-tools C CXX
)

add_compile_options(
    -std=c++11
    -Wall
    -Werror
)

add_executable(
    ktx ktx.cpp
)
