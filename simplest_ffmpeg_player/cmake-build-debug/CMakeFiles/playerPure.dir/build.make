# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.6

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /Applications/CLion.app/Contents/bin/cmake/bin/cmake

# The command to remove a file.
RM = /Applications/CLion.app/Contents/bin/cmake/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/kevinjfliu/svns/simplest_ffmpeg_player

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/kevinjfliu/svns/simplest_ffmpeg_player/cmake-build-debug

# Include any dependencies generated for this target.
include CMakeFiles/playerPure.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/playerPure.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/playerPure.dir/flags.make

CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o: CMakeFiles/playerPure.dir/flags.make
CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o: ../simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/kevinjfliu/svns/simplest_ffmpeg_player/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++   $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o -c /Users/kevinjfliu/svns/simplest_ffmpeg_player/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp

CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.i"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/kevinjfliu/svns/simplest_ffmpeg_player/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp > CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.i

CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.s"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/kevinjfliu/svns/simplest_ffmpeg_player/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp -o CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.s

CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o.requires:

.PHONY : CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o.requires

CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o.provides: CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o.requires
	$(MAKE) -f CMakeFiles/playerPure.dir/build.make CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o.provides.build
.PHONY : CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o.provides

CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o.provides.build: CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o


# Object files for target playerPure
playerPure_OBJECTS = \
"CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o"

# External object files for target playerPure
playerPure_EXTERNAL_OBJECTS =

playerPure: CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o
playerPure: CMakeFiles/playerPure.dir/build.make
playerPure: CMakeFiles/playerPure.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/Users/kevinjfliu/svns/simplest_ffmpeg_player/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable playerPure"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/playerPure.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/playerPure.dir/build: playerPure

.PHONY : CMakeFiles/playerPure.dir/build

CMakeFiles/playerPure.dir/requires: CMakeFiles/playerPure.dir/simplest_ffmpeg_decoder_pure/simplest_ffmpeg_decoder_pure.cpp.o.requires

.PHONY : CMakeFiles/playerPure.dir/requires

CMakeFiles/playerPure.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/playerPure.dir/cmake_clean.cmake
.PHONY : CMakeFiles/playerPure.dir/clean

CMakeFiles/playerPure.dir/depend:
	cd /Users/kevinjfliu/svns/simplest_ffmpeg_player/cmake-build-debug && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/kevinjfliu/svns/simplest_ffmpeg_player /Users/kevinjfliu/svns/simplest_ffmpeg_player /Users/kevinjfliu/svns/simplest_ffmpeg_player/cmake-build-debug /Users/kevinjfliu/svns/simplest_ffmpeg_player/cmake-build-debug /Users/kevinjfliu/svns/simplest_ffmpeg_player/cmake-build-debug/CMakeFiles/playerPure.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/playerPure.dir/depend

