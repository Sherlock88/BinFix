# Check for cmake minimum version
cmake_minimum_required(VERSION 2.8)

# Name of DynamoRIO client
project(BinVar)

# Version number of DynamoRIO client
set (BinVar_VERSION_MAJOR 1)
set (BinVar_VERSION_MINOR 0)

# If DynamoRIO is not installed, set the path to the package
# where CMake configuration files are located
# http://dynamorio.org/docs/using.html#sec_build
# Either set the path in CMakeLists.txt (here)
set(DynamoRIO_DIR ../deps/DynamoRIO/cmake)

# Or pass the path to cmake from command-line
# The variable DynamoRIO_DIR gets cached as a result of this,
# so you only need this -D argument once (unless the required
# path changes or you delete your CMakeCache file, etc.)
# cmake -DDynamoRIO_DIR:PATH=/path/to/DR/cmake/configuration/directory

find_package(DynamoRIO)
if (NOT DynamoRIO_FOUND)
 	message(FATAL_ERROR "DynamoRIO package required to build")
endif(NOT DynamoRIO_FOUND)

# Add the DR clinet as a SHARED library to the project
add_library(binvar SHARED source/binvar.cpp)
add_library(binextract SHARED source/binextract.cpp)

# Configure DR client
configure_DynamoRIO_client(binvar)
configure_DynamoRIO_client(binextract)