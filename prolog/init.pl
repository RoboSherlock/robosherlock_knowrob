%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% dependencies
:- register_ros_package(knowrob_common).
:- register_ros_package(knowrob_objects).
:- register_ros_package(knowrob_vis).
:- register_ros_package(knowrob_srdl).
:- register_ros_package(robosherlock_knowrob).

:- owl_parser:owl_parse('package://iai_kitchen/owl/iai-kitchen-objects.owl').
:- rdf_db:rdf_register_prefix(kitchen, 'http://knowrob.org/kb/iai-kitchen.owl#', [keep(true)]).

:- owl_parser:owl_parse('package://robosherlock_knowrob/owl/rs_components.owl').
:- rdf_db:rdf_register_prefix(rs_components, 'http://knowrob.org/kb/rs_components.owl#', [keep(true)]).


% :- use_module(library(rs_plan_pipeline)).
:- use_module(library(rs_query_interface)).
:- use_module(library(rs_query_reasoning)).
:- use_module(library(rs_similar_objects)).


% for testing%

%:- owl_instance_from_class(rs_components:'CollectionReader',_).
%:- owl_instance_from_class(rs_components:'ImagePreprocessor',_).
%:- owl_instance_from_class(rs_components:'RegionFilter',_).
%:- owl_instance_from_class(rs_components:'NormalEstimator',_).
%:- owl_instance_from_class(rs_components:'PlaneAnnotator',_).


%:- owl_instance_from_class(rs_components:'ImageSegmentationAnnotator',I),set_annotator_output_type_domain(I,[rs_components:'Round'],rs_components:'RsSceneCluster').
%:- owl_instance_from_class(rs_components:'PointCloudClusterExtractor',I),set_annotator_output_type_domain(I,[rs_components:'Box'],rs_components:'RsSceneCluster').


%:- owl_instance_from_class(rs_components:'ClusterMerger',I),set_annotator_input_type_constraint(I,[rs_components:'Flat'],rs_components:'RsSceneCluster').
%% :- owl_instance_from_class(rs_components:'ClusterFilter',_).

%:- owl_instance_from_class(rs_components:'Cluster3DGeometryAnnotator',_).

%:- owl_instance_from_class(rs_components:'PrimitiveShapeAnnotator',I),set_annotator_output_type_domain(I,[rs_components:'Box',rs_components:'Round'],rs_components:'RsAnnotationShape'),set_annotator_output_type_domain(I,[rs_components:'Red',rs_components:'Green'],rs_components:'RsAnnotationSemanticcolor').

%:- owl_instance_from_class(rs_components:'ClusterColorHistogramCalculator',I),set_annotator_output_type_domain(I,[rs_components:'Yellow',rs_components:'Blue'],rs_components:'RsAnnotationSemanticcolor').

%:- owl_instance_from_class(rs_components:'SacModelAnnotator',I),set_annotator_output_type_domain(I,[rs_components:'Cylinder'],rs_components:'RsAnnotationShape'), set_annotator_input_type_constraint(I,[rs_components:'Red'],rs_components:'RsAnnotationSemanticcolor').

%:- assert(requestedValueForKey(shape,rs_components:'Cylinder')).

