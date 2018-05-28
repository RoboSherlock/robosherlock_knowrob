#!/usr/bin/env python
# -*- coding: utf-8 -*

import string
import rospkg
import os
import ntpath

from kanren import *
from lxml import etree

NS = "{http://uima.apache.org/resourceSpecifier}"
ACCEPTABLE_PERCEPTION_CAPABILITY_NAMES = ["Perceive3DDepthCapability", "PerceiveColorCapability", "PerceiveThermalCapability"]


is_a_rs_type = Relation()
is_a_rs_component = Relation()
needs_input = Relation()
produces_output = Relation()


key_to_type = {"shape": ["rs.annotation.Shape"],
               "color": ["rs.annotation.SemanticColor"],
               "type": ["rs.annotation.Classification", "rs.annotation.Detection"],
               "location": ["rs.annotation.TFLocation"],
               "size": ["rs.annotation.Geometry"]}



class Annotator:
    def __init__(self, name, subclass_of):
        self.name = name
        self.subclass_of = subclass_of
        self.inputs = []
        self.outputs = []
        self.required_capabilities = []

    # calculate the name that should be written to the Ontology from the given name
    def ontology_name(self):
        return self.name

    # calculate the superclass that should be written to the Ontology from the given subclass_of attribute
    def ontology_subclass_of(self):
        return self.subclass_of[:1].upper()+self.subclass_of[1:]+"Component"

    def inputs(self):
        return map(convertTypeToONewFormat, self.inputs)

    def outputs(self):
        return map(convertTypeToONewFormat, self.outputs)

def convertTypeToONewFormat(s):
    """Converts something like rs.pcl.PointCloud to RsPclPointcloud"""
    return string.capwords(s, '.').replace(".", "").replace("_", "").replace("rs", "Rs")


# Get path of Type files from Typesystem
def getTSPaths():
    rospack = rospkg.RosPack()
    paths = []
    paths.append(rospack.get_path('robosherlock'))
    package_names = rospack.get_depends_on('robosherlock')
    for pn in package_names:
        paths.append(rospack.get_path(pn))
    for i in range(len(paths)):
        paths[i] += str('/descriptors/typesystem')

    ts_paths = []

    for pkg in paths:
        print pkg
        try:
            for filename in os.listdir(pkg):
                print filename
                filepath = os.path.join(pkg, filename)
                (name, ext) = os.path.splitext(filename)
                if not os.path.isfile(filepath) or ext != ".xml" or filename == "all_types.xml":
                    continue;
                ts_paths.append(filepath)
        except OSError:
            print "Path does not exist"
    return ts_paths

def getpackagepaths():

    rospack = rospkg.RosPack()
    paths = []
    paths.append(rospack.get_path('robosherlock'))
    package_names = rospack.get_depends_on('robosherlock')
    print('Packages depending on RoboSherlock:', package_names)
    for pn in package_names:
        paths.append(rospack.get_path(pn))

    for i in range(len(paths)):
        paths[i] += str('/descriptors/annotators')
    return paths

def getAnnotatorIOs(filepath):
    """Fetch the I/O from the annotator definition. Input: full filepath for a annotator
    description XML.
    Returns: A tuple of that form: (list-of-inputs, list-of-outputs)"""
    outputs = []
    inputs = []
    tree = etree.parse(filepath)
    root = tree.getroot()
    for element in root.iter("*"):
        if element.tag == NS+'sofaName':
            # print "sofaName: "+ element.text
            inputs.append(element.text)
        if element.tag == NS+'capability':
            t = {}
            for e in element:
                if e.tag == NS + 'outputs':
                    for types in e.findall(NS+'type'):
                        # print "Output Type: " + types.text
                        outputs.append(types.text)
    return (inputs,outputs)


def getAnnotatorNames():
    paths = getpackagepaths()
    # print paths
    annotators = []
    atypes = []

    for p in paths:
        print p
        if os.path.isdir(p) == False:
            continue;

        for subdir in os.walk(p).next()[1]:
            atypes.append(subdir)
            subdirpath = os.path.join(p, subdir)
            for filename in os.listdir(subdirpath):
                filepath = os.path.join(subdirpath, filename)
                (name, ext) = os.path.splitext(filename)
                if not os.path.isfile(filepath) or ext != ".xml":
                    continue;
                facts(is_a_rs_component, (name, subdir))
                annotators.append(Annotator(name, subdir))
                # annotators.append((subdir,name))
                # print "Annotator:" + filepath
                (inputs, outputs) = getAnnotatorIOs(filepath)
                annotators[-1].inputs = inputs
                for i in inputs:
                    facts (needs_input, (name, i))

                annotators[-1].outputs = outputs
                for o in outputs:
                    facts (produces_output, (name, o))

        for filename in os.listdir(p):
            filepath = os.path.join(p, filename)
            (name, ext) = os.path.splitext(filename)
            if not os.path.isfile(filepath) or ext != ".xml":
                continue;

            annotators.append(Annotator(name, 'RoboSherlock'))
            facts(is_a_rs_component, (name, 'RoboSherlock'))

            (inputs, outputs) = getAnnotatorIOs(filepath)
            annotators[-1].inputs = inputs
            for i in inputs:
                facts(needs_input, (name, i))

            annotators[-1].outputs = outputs
            for o in outputs:
                facts(produces_output, (name, o))
    return (atypes, annotators)


def getRoboSherlockTypes():
    """Read the required information from the RoboSherlock Typesystem"""
    result_list = []
    ts_paths = getTSPaths()
    types = []
    for ts in ts_paths:
        (name, ext) = os.path.splitext(ntpath.basename(ts))
        tree = etree.parse(ts)
        root = tree.getroot()
        for element in root.iter("*"):
            if element.tag == NS + 'typeDescription':
                t = {}
                for e in element:
                    if e.tag == NS + 'name':
                        t['type'] = e.text
                    if e.tag == NS + 'supertypeName':
                        t['supertype'] = e.text
                types.append(t)

    for t in types:
        subclassof = convertTypeToONewFormat(t['supertype'])
        classname = convertTypeToONewFormat(t['type'])
        if subclassof == "UimaCasTop":
            subclassof = "RoboSherlockType"

        facts(is_a_rs_type, (classname, subclassof))


if __name__ == "__main__":


    # x = var()
    #
    # facts(is_a_rs_component, ("PrimitiveShapeAnnotator", "AnnotatorComponent"),
    #       ("PointCloudClusterExtractor", "SegmentationComponent"),
    #       ("ClusterColorHistogram", "AnnotatorComponent")
    #       )
    #
    # facts(needs_input, ("PrimitiveShapeAnnotator", "RSPointCloud"),
    #       ("PrimitiveShapeAnnotator", "RSPlane"))
    #
    # facts(produces_output, ("PrimitiveShapeAnnotator", "RSShapeAnnotation"))
    #
    # y = var()
    # res = run(0, (x, y), (is_a_rs_component, x, y), (produces_output, x, "RSShapeAnnotation"))
    #
    # for r in res:
    #     print r
    #     res = run(0, x, (needs_input, r[0], x))
    #     print res
    getRoboSherlockTypes()
    (atypes, annotators) = getAnnotatorNames()
    # for t in types:
    #     facts(is_a_rs_type,(t[0],t[1]))
    # print types

    x = var()
    y = var()
    res = run (0,x, (is_a_rs_type,x,'RsCoreAnnotation'))
    print res

    res = run (0,x, (produces_output,x,'rs.annotation.Features'))
    print res
# run()
