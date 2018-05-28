cmake_minimum_required(VERSION 2.8.3)
project(robosherlock_knowrob)


find_package(catkin REQUIRED rosprolog
             knowrob_common knowrob_actions knowrob_srdl robosherlock iai_maps 
             robosherlock_msgs json_prolog)

find_package(PkgConfig)
pkg_check_modules(SWIPL REQUIRED swipl)
include_directories(${SWIPL_INCLUDE_DIRS})
link_directories(${SWIPL_LIBRARY_DIRS})
message(STATUS "SWIPL found.")

find_package(RapidJSON REQUIRED)
if(${RapidJSON_FOUND})
    add_definitions(-DWITH_JSON -DRAPIDJSON_HAS_STDSTRING -DWITH_JSON_PROLOG)
endif()    

catkin_package(
)

###########
## Build ##
###########

## Specify additional locations of header files
## Your package locations should be listed before other locations
include_directories(
        ${catkin_INCLUDE_DIRS}
        )

rs_add_library(rs_prologQueries
    src/PrologQueries.cpp)
target_link_libraries(rs_prologQueries 
	${robosherlock_LIBRARIES} 
    ${SWIPL_LIBRARIES}
	${catkin_LIBRARIES})
