#!/bin/bash

function is-valid-trace() {
    YAML_PP_TRACE=1 YAML_TEST_DIR=$1 prove -lrv t/10.parse-valid.t
}

function is-valid() {
    YAML_PP_DEBUG=1 YAML_TEST_DIR=$1 prove -lrv t/10.parse-valid.t
}

function is-invalid-trace() {
    YAML_PP_TRACE=1 YAML_TEST_DIR=$1 prove -lrv t/11.parse-invalid.t
}

function is-invalid() {
    YAML_PP_DEBUG=1 YAML_TEST_DIR=$1 prove -lrv t/11.parse-invalid.t
}

function test-dump() {
    YAML_TEST_DIR=$1 prove -lrv t/20.dump.t
}
function test-emit() {
    YAML_PP_EMIT_DEBUG=1 YAML_TEST_DIR=$1 prove -lrv t/21.emit.t
}

function json-load() {
    YAML_PP_LOAD_TRACE=1 YAML_TEST_DIR=$1 prove -lrv t/12.load-json.t
}

alias dmake="make -f Makefile.dev"
