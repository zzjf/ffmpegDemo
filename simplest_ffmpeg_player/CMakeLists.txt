cmake_minimum_required(VERSION 3.6)

project(ffmpegDemo)

include_directories(/usr/local/include)
link_directories(/usr/local/lib)
link_libraries(SDL2 SDL2main avcodec)

aux_source_directory(./simplest_video_play_sdl2 sdl2)
add_executable(playerSdl2 ${sdl2})

aux_source_directory(./simplest_ffmpeg_decoder_pure pure)
add_executable(playerPure ${pure})

set(libs avcodec avformat avutil swscale)
aux_source_directory(./simplest_ffmpeg_player_su su)
add_executable(playerSu ${su})
target_link_libraries(playerSu ${libs})

aux_source_directory(./simplest_ffmpeg_player no)
add_executable(player ${no})
target_link_libraries(player ${libs})