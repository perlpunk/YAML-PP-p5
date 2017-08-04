#!/bin/bash

function is-valid() {
    YAML_PP_TRACE=1 YAML_TEST_DIR=$1 prove -lrv t/10.parse.t
}

function is-invalid() {
    YAML_PP_TRACE=1 YAML_TEST_DIR=$1 prove -lrv t/11.invalid.t
}
function test-dump() {
    YAML_TEST_DIR=$1 prove -lrv t/20.dump.t
}

function json-load() {
    YAML_PP_LOAD_TRACE=1 YAML_TEST_DIR=$1 prove -lrv t/12.load-json.t
}

alias dmake="make -f Makefile.dev"
