#!/bin/bash

function is-valid() {
    YAML_PP_TRACE=1 YAML_TEST_DIR=$1 prove -lrv t/10.parse.t
}

alias dmake="make -f Makefile.dev"
