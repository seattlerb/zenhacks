#!/bin/bash

GEM_SKIP=ParseTree ruby -I../../ParseTree/dev/lib:../../ruby_to_c/dev:. -w fixloops-bad.rb
