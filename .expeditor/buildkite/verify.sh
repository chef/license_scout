#!/bin/bash

set -ue

export USER="root"

echo "--- bundle install"
bundle config --local path vendor/bundle
bundle install --jobs=7 --retry=3

echo "+++ bundle exec task"
bundle exec rake
