#!/bin/bash

N=$1

if [ -z $N ]; then N=5000; fi

rm -rf ~/.ruby_inline
sync; sync; sync

echo N=$N

echo
echo ruby vanilla:
time ruby factorial.rb $N

echo
echo ruby profiler:
time ruby -rprofile factorial.rb $N

echo
echo zenspider profiler:
GEM_SKIP=RubyInline \
time ruby -I.:../../RubyInline/dev -rzenprofile factorial.rb $N

# shugo's version
# time ruby -I.:lib -runprof factorial.rb $N 2>&1 | head
