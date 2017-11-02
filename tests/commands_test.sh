#!/bin/bash

export GREP="grep"
. tests/assert.sh -v

src="./gitlab-check.sh"

assert_raises "$src" 1
assert_contains "$src -h" "gitlab-check" 
assert_contains "$src -h" "GitLab Checker"

assert_end