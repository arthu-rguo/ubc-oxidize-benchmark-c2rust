#!/bin/bash

set -o errexit -o nounset -o pipefail
echo "project = $1"
echo "src     = $2"
echo "dst     = $3"

# todo: assuming cmake for now, but this should be configurable
# gcc is the default compiler, but c2rust uses clang internally
get_compile_commands () { [ -f compile_commands.json ] || cmake -DCMAKE_C_COMPILER=$(which clang-6.0) -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .; }

mkdir -p /tmp/workspace && cp -r $2/$1 /tmp/workspace
cd /tmp/workspace/$1
get_compile_commands

# the interesting part is --reorganize-definitions. this is the
# tragically short-lived c2rust feature that attempts to gather
# duplicate definitions from includes and convert them into use
# statements
RUST_BACKTRACE=1 c2rust transpile -e --fail-on-error --reduce-type-annotations --reorganize-definitions compile_commands.json

# copy all the .rs and .toml files to the destination directory
mkdir -p $3/$1 && for generated_file in $(find . -name "*.rs" -o -name "*.toml"); do cp --parents $generated_file $3/$1; done
