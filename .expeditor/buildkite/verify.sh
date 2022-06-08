#!/bin/bash

set -ue

export USER="root"

echo "--- bundle install"
bundle config --local path vendor/bundle
bundle install --jobs=7 --retry=3 --verbose

echo "+++ bundle exec task"
bundle exec rake
