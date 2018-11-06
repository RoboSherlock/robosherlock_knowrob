cmake_minimum_required(VERSION 2.8.3)
project(robosherlock_knowrob)


find_package(catkin REQUIRED rosprolog rapidjson_ros 
             knowrob_common knowrob_actions knowrob_srdl iai_maps 
             robosherlock_msgs json_prolog)

find_package(PkgConfig)
pkg_check_modules(SWIPL REQUIRED swipl)
include_directories(${SWIPL_INCLUDE_DIRS} ${catkin_INCLUDE_DIRS})
link_directories(${SWIPL_LIBRARY_DIRS})
message(STATUS "SWIPL found.")

add_definitions(-DRAPIDJSON_HAS_STDSTRING)
 
catkin_package(CATKIN_DEPENDS  knowrob_common knowrob_actions knowrob_srdl robosherlock_msgs json_prolog)

add_library(rs_prologQueries SHARED src/PrologQueries.cpp)
target_link_libraries(rs_prologQueries ${robosherlock_LIBRARIES} 
    ${SWIPL_LIBRARIES} ${catkin_LIBRARIES})
add_dependencies(rs_prologQueries ${${PROJECT_NAME}_EXPORTED_TARGETS} ${catkin_EXPORTED_TARGETS})

install(DIRECTORY owl/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/owl)

install(DIRECTORY prolog/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/prolog)
