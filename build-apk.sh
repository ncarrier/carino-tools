#!/bin/bash

# adapt this to your situation
export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"

# updates the build.xml file for ant
android update project --path .

# cleaning is mandatory since previouseclipse builds can mess up things
ant clean

# do build the result will be placed in bin/CarinoSteeringWheel-debug.apk
ant debug

