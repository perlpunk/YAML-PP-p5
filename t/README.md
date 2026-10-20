# YAML Test Suite checks

Parser tests read `in.yaml` and compare the resulting events with `test.event`.
JSON and dump/reload tests also exercise the parser and constructor.

Emitter tests read the event fixture directly.
This keeps emitter coverage independent of parser limitations.
`test_suite_to_event` decodes collection styles, scalar styles, anchors, tags,
and escaped scalar content from those fixtures.

Exact serialization tests use the presentation instructions in `emit.yaml`,
falling back to `out.yaml` or `in.yaml` when necessary.
They require the reference to preserve the input's resolved values, types,
tags, anchors, aliases, and node structure before using its presentation.
The emitter output must match the reference text exactly.
The reference text and expected event fixtures are never rewritten.

Preserved-flow and forced-flow tests use the input event fixture with their
requested collection styles.
They compare emitted events and independently compare resolved input and
output data and node properties.
An unadorned empty plain sequence item becomes `null` in forced flow, where
an omitted item has no legal representation.
Anchored and explicitly tagged empty nodes retain their empty presentation.

Some valid collection-key references require parser fixes maintained on
separate pull requests.
When the parser cannot read a reference, the independent emitter check accepts
only an exact match to that reference and labels the limitation explicitly.
Other layouts still require successful reparsing.
Integration testing with those parser fixes exercises the full round trip.
In particular, parser checks for `6BFJ`, `9MMW`, and `M2N8:01` still depend
on that separate flow-key fix.
Those earlier parser changes are excluded from this branch.

Run `make test` for normal coverage and `make test-all PROVE_FLAGS=-v` to
include TODO cases and inspect their individual results.
If the environment exports `NO_COLOR`, unset it for these commands because
the existing highlighting tests expect color output.

`TEST_ALL=1` runs skipped cases as TODO tests.
Inspect those failures as well as the test process's exit status.
