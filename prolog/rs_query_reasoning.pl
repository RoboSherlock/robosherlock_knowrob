%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Rules for planing a new pipeline based on keys extracted from a query
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- module(rs_query_resoning,
    [
  compute_annotators/1,
  annotators/1,
  compute_annotator_outputs/2,
  compute_annotator_inputs/2,
  reset_planning/0,
  annotator_outputs/2,
  annotator_inputs/2,
  type_available/1,
  annotator_in_dependency_chain_of/2,
  dependency_chain_as_set_for_annotator/2,
  dependency_chain_ordering/3,
  ordered_dependency_chain_for_annotator/2,
  annotator_missing_inputs/2,
  annotators_satisfying_atleast_one_input/2,
  annotators_satisfying_direct_inputs_of/2,
  get_required_annotators_for_annotator_list/2,
  annotatorlist_requirements_fulfilled/1,
  get_missing_annotators/2,
  can_inputs_be_provided_for_annotator_list/1,
  build_pipeline/2,
  annotators_for_predicate/2,
  annotators_for_predicates/2,
  build_pipeline_from_predicates/2,
  set_annotator_domain/2,
  compute_annotator_domain/2
]).

:- rdf_meta
   compute_annotator_inputs(r,r),
   build_pipeline(t,t),
   set_annotator_domain(r,t),
   compute_annotator_domain(r,t).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pipeline Planning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

compute_annotators(A) :- 
	owl_subclass_of(A,rs_components:'RoboSherlockComponent'),
        not(A = 'http://knowrob.org/kb/rs_components.owl#RoboSherlockComponent'), 
        not(A = 'http://knowrob.org/kb/rs_components.owl#AnnotationComponent'), 
        not(A = 'http://knowrob.org/kb/rs_components.owl#DetectionComponent'), 
        not(A = 'http://knowrob.org/kb/rs_components.owl#IoComponent'), 
        not(A = 'http://knowrob.org/kb/rs_components.owl#PeopleComponent'), 
        not(A = 'http://knowrob.org/kb/rs_components.owl#SegmentationComponent'). 
        

        
        
% cache the annotators
:- forall(compute_annotators(A), assert(annotators(A)) ).



% assert domain restriction for an individual generated from a RoboSherlockComponents
set_annotator_domain(AnnotatorI, Domain):-
    owl_individual_of(AnnotatorI,rs_components:'RoboSherlockComponent'),
    owl_restriction_assert(restriction(rs_components:'outputDomain',all_values_from(union_of(Domain))),R),
    rdf_assert(AnnotatorI,rdf:type,R).

compute_annotator_domain(AnnotatorI, Domain):-
    owl_individual_of(AnnotatorI,rs_components:'RoboSherlockComponent'),
    owl_has(AnnotatorI,rdf:type,R),   
    owl_has(R,owl:onProperty,rs_components:'outputDomain'), 
    rdf_has(R,owl:allValuesFrom,V),owl_description(V,union_of(Domain)).


% Get outputs of Annotator
compute_annotator_outputs(Annotator,Output) :- 
	% current_robot(R),!,
	annotators(Annotator), 
	owl_class_properties(Annotator,rs_components:'perceptualOutput',Output).
	%  action_feasible_on_robot(Annotator, R).

% Get inputs of Annotator
compute_annotator_inputs(Annotator,Input) :- 
	% current_robot(R),!,
	annotators(Annotator), 
	owl_class_properties(Annotator,rs_components:'perceptualInputRequired',Input).
	%  action_feasible_on_robot(Annotator, R).

% cache outputs/inputs
:- forall(compute_annotator_outputs(A,O), assert(annotator_outputs(A,O)) ).
:- forall(compute_annotator_inputs(A,I), assert(annotator_inputs(A,I)) ).

% If you changed the robot model or something else in this code,
% call this rule to cache the annotators and their I/Os again.
reset_planning:- retractall(annotator_outputs(_,_)),
	retractall(annotator_inputs(_,_)),
	retractall(annotators(_)),
	forall(compute_annotators(A), assert(annotators(A)) ),
	forall(compute_annotator_outputs(A,O), assert(annotator_outputs(A,O)) ),
	forall(compute_annotator_inputs(A,I), assert(annotator_inputs(A,I)) ).

% Get every type that can be put out by any annotator
type_available(Output) :- 
	annotator_outputs(_,Output).

% Check if Annotator A is somewhere in the Depedency chain of D.
% This means for example in RoboSherlock, where the CollectionReader should be at
% the first place in every pipeline:
% annotator_in_dependency_chain_of(CollectionReader,SomeShapeAnnotator) should be true.
% annotator_in_dependency_chain_of(SomeShapeAnnotator, CollectionReader) should be false.
% annotator_in_dependency_chain_of(SomeShapeAnnotator, imagePreprocessor) should be false.
% annotator_in_dependency_chain_of(X, Collectionreader) should be false.
%
% Trivial case: A is in the dependency chain of D, if A provides a type that D needs.
annotator_in_dependency_chain_of(A, D) :- 
	annotator_outputs(A,Input),
	annotator_inputs(D, Input).

% Recursive case: A is in the Dependency chain of D, if A provides a Type
% that X needs, and X provides a type that D needs.
annotator_in_dependency_chain_of(A, D) :- 
	annotator_outputs(A,Input),
	annotator_inputs(X, Input),
	annotator_in_dependency_chain_of(X, D).

% calculate the full dependency chain for a given
% Annotator, include the annotator itself. The chain 
% MUST NOT be in the correct order
dependency_chain_as_set_for_annotator(Annotator,S) :-
	L=[Annotator],
	setof(X,annotator_in_dependency_chain_of(X,Annotator),D),
	append(L,D,S); % Either a set of dependencies can be calculated
	S=[]. % or we return an empty list, when no dependencies are present

% AnnotatorA < AnnotatorB when A is somewhere in the beginning
% of the dependency chain of B
dependency_chain_ordering(R, AnnotatorA, AnnotatorB) :-
	annotator_in_dependency_chain_of(AnnotatorA, AnnotatorB) -> R = '<' ; R = '>'.
% Order the output of dependency_chain_as_set_for_annotator in a manner
% that the evaluation order in L is correct.
ordered_dependency_chain_for_annotator(Annotator,L) :-
	dependency_chain_as_set_for_annotator(Annotator,AnnotatorChainSet),
	predsort(dependency_chain_ordering, AnnotatorChainSet, L).


% Can an input never be satisified?
annotator_missing_inputs(Annotator,Missing) :- 
	findall(Input, (annotator_inputs(Annotator, Input),
	not(type_available(Input)) ), Missing).

% Get a list caled AnnotatorSatisfyingInput, that
% includes all annotators that provide _one_ input of Annotator A.
annotators_satisfying_atleast_one_input(Annotator, AnnotatorSatisfyingInput):-
	annotator_inputs(Annotator, Input),
	setof(X, annotator_outputs(X,Input), AnnotatorSatisfyingInput).

% Get a List of Annotators, that provide the required inputs of
% _ALL_ inputs of A
annotators_satisfying_direct_inputs_of(Annotator, AnnotatorSet):-
	setof(X, annotators_satisfying_atleast_one_input(Annotator, X), L),
	flatten(L, AnnotatorSet);
	AnnotatorSet = []. % Return empty set, when a annotator doesn't need any inputs

get_required_annotators_for_annotator_list(AnnotatorList,RequiredAnnotators):-
	maplist(annotators_satisfying_direct_inputs_of, AnnotatorList, List),
	flatten(List, FlattenedList),
	list_to_set(FlattenedList, RequiredAnnotators).

% Check, if all the required annotators of the annotators are in the given list.
% WARNING: This does NOT work if you pass a list, that has unsatisfiable
% input requirements. This means, that the input of an Annotator
% is not the Result of ANY Annotator in the KnowledgeBase.
annotatorlist_requirements_fulfilled(AnnotatorList):-
	get_required_annotators_for_annotator_list(AnnotatorList, ReqA),!,
	% is ReqA a Subset of AnnotatorList? 
	subset(ReqA, AnnotatorList).

% Take a List of Annotators called L, calculate all the required inputs
% and the Annotators that do provide them.
% Add the Annotators to L.
% Repeat, until the size of L doesn't change.
% add_required_annotators_until_inputs_satisfied(AnnotatorList, ResultList).

% Take a List of Annotators, calculate it's dependencies on other
% Annotators and add them to the ResultList.
get_missing_annotators(AnnotatorList, ResultList):-
	maplist(dependency_chain_as_set_for_annotator,AnnotatorList, L),
	flatten(L, FlattenedList),
	list_to_set(FlattenedList, ResultList).

% Check, if the required inputs of the Anntators in AnnotatorList
% can be provided by any of the Annotators in the System.
% If the Annotator doesn't require any inputs, the method will be true.
can_inputs_be_provided_for_annotator_list(AnnotatorList):-
	% check for all members of AnnotatorList
	forall(member(R,AnnotatorList),
	  % The Annotator doesn't need any inputs
	  (\+ annotator_inputs(R,_) ;
	    % or: EVERY input will be provided by some annotator.
	    forall(annotator_inputs(R,T), annotator_outputs(_,T))
	  )
	).

% TODO: Consistency Checks! Check the dependency graph for the absence of cycles.
% TODO: Test with multiple inputs 

% ListOfAnnotators: A List of Annotators that should be run. The list does not have to include the necessary dependencies for the Annotators nor must be in the correct order.
% EvaluationList: A List of Annotators that form a complete Pipeline. The Annotators should be in the correct evaluation order

build_pipeline(ListOfAnnotators,EvaluationList):-
	% Are there any requested types that can't be calculated by the system?
	can_inputs_be_provided_for_annotator_list(ListOfAnnotators) ->
	  (annotatorlist_requirements_fulfilled(ListOfAnnotators) ->
	    % If requirements are already fulfilled, bring everything in the correct order and return
	    predsort(dependency_chain_ordering, ListOfAnnotators, EvaluationList);
	    % else: get the missing annotators to complete the list and sort it.
	    get_missing_annotators(ListOfAnnotators, FullListOfAnnotators),!,
	    predsort(dependency_chain_ordering, FullListOfAnnotators, EvaluationList)
	  )	
	; write('** WARNING: One or more inputs of the given List of Annotators can not be computed by an Algorithm in the KnowledgeBase **'),
	fail.


% Map a predefined set of predicates to Annotator Outputs
annotators_for_predicate(shape,A) :-
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationShape' ).
annotators_for_predicate(color,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationSemanticcolor' ).
annotators_for_predicate(size,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationGeometry' ).
annotators_for_predicate(location,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationTflocation' ).
annotators_for_predicate(logo,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationGoggles' ).
annotators_for_predicate(text,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationGoggles' ).
annotators_for_predicate(product,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationGoggles' ).
annotators_for_predicate(class,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationDetection' ).
annotators_for_predicate(detection,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationDetection' ).
annotators_for_predicate(handle,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationHandleannotation' ).
annotators_for_predicate(cylindrical_shape,A) :- 
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationCylindricalshape' ).
annotators_for_predicate(obj-part,A) :-
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationClusterpart' ).
annotators_for_predicate(inspect,A) :-
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationClusterpart' ).
annotators_for_predicate(contains,A) :-
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsdemosAcatSubstance' ).
annotators_for_predicate(volume,A) :-
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsdemosAcatVolume' ).
annotators_for_predicate(ingredient,A) :-
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsdemosRobohowPizza' ).
annotators_for_predicate(type,A) :-
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationDetection' ).
annotators_for_predicate(cad-model,A) :-
	annotator_outputs(A,'http://knowrob.org/kb/rs_components.owl#RsAnnotationPoseannotation' ).


annotators_for_predicates(Predicates, A):-
	member(P,Predicates), 
	annotators_for_predicate(P, A).


build_pipeline_from_predicates(ListOfPredicates,Pipeline):-
	setof(X,annotators_for_predicates(ListOfPredicates, X), Annotators), % Only build one list of annotators for the given Predicates
	build_pipeline(Annotators, TempPipeline),%same as above
	build_pipeline(TempPipeline,P),
	build_pipeline(P,Pipeline).


