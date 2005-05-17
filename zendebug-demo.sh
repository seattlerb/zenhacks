#!/bin/bash

export GEM_SKIP=RubyInline

rm -rf ~/.ruby_inline

type=$1
if [ -z "$1" ]; then
    type=help
fi

if [ $type = "help" ]; then
    echo "usage: $0 type"
    echo "  type ="
    echo "    native   - run factorial with native ruby"
    echo "    debug    - run factorial with ruby debugger"
    echo "    zendebug - run factorial with zendebugger"
fi

if [ $type = "native" ]; then
    time ruby -I../../RubyInline/dev misc/factorial.rb 5000
fi

if [ $type = "debug" ]; then
    echo "c" | time ruby -rdebug -I../../RubyInline/dev misc/factorial.rb 5000
fi

if [ $type = "zendebug" ]; then
    echo "c" | time ruby -rzendebug -Ilib:../../RubyInline/dev misc/factorial.rb 5000
fi

if [ $type = "profile" ]; then
    time ruby -rprofile -rzendebug -Ilib:../../RubyInline/dev misc/factorial.rb 500
fi
