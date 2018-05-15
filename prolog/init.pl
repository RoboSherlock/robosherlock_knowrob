%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% dependencies
:- register_ros_package(knowrob_common).
:- register_ros_package(knowrob_objects).
:- register_ros_package(knowrob_vis).

:- register_ros_package(robosherlock_knowrob).

:- use_module(library(rs_plan_pipeline)).
:- use_module(library(rs_query_interface)).
:- use_module(library(rs_similar_objects)).
:- use_foreign_library('rs_prologrulescpp.so').


%:- owl_parser:owl_parse('package://iai_kitchen/owl/iai-kitchen-objects.owl').
:- owl_parser:owl_parse('package://robosherlock_knowrob/owl/rs_iai_objects.owl').

:- rdf_db:rdf_register_prefix(kitchen, 'http://knowrob.org/kb/iai-kitchen.owl#', [keep(true)]).
%:- rdf_db:rdf_register_prefix(rs_objects, 'http://knowrob.org/kb/rs_objects.owl#', [keep(true)]).

:- owl_parser:owl_parse('package://robosherlock_knowrob/owl/rs_components.owl').
:- rdf_db:rdf_register_prefix(rs_components, 'http://knowrob.org/kb/rs_components.owl#', [keep(true)]).


