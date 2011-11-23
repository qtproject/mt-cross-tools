INCLUDE(CMakeForceCompiler)

# this one is important
SET(CMAKE_SYSTEM_NAME Linux)

# specify the cross compiler
CMAKE_FORCE_C_COMPILER(${CROSS_COMPILE}gcc GNU)
CMAKE_FORCE_CXX_COMPILER(${CROSS_COMPILE}g++ GNU)

# where is the target environment 
SET(CMAKE_FIND_ROOT_PATH  ${SYSROOT})

# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)