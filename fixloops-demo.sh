#!/bin/bash

GEM_SKIP=ParseTree ruby -Ilib:../../ParseTree/dev/lib:../../ruby_to_c/dev:. -w misc/fixloops-bad.rb
