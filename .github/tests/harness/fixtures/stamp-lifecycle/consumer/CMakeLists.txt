add_library(consumer SHARED consumer.c)
add_executable(lifecycle-check main.c)
target_link_libraries(lifecycle-check PRIVATE consumer)
