#
# Copyright:: Copyright 2016, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

source "https://rubygems.org"

gemspec

group :development do
  gem "rake", "~> 10.0"
  gem "rspec"
  gem "pry"
  gem "rb-readline"
  gem "chefstyle"
  gem "vcr"
  gem "webmock"
end

# Package Berkshelf with LicenseScout in the Hart
#
# We do not have berkshelf as a dependency because some of its dependencies
# can not be installed on uncommon platforms like Solaris which we need to
# support. If a project needs to collect license information for a berkshelf
# project it needs to include it seperately in its gem bundle. We have a nice
# error message when they do not. But we add berkshelf as a development
# dependency so that we can run our tests.
group :habitat do
  gem "berkshelf", " ~> 4.3"
end
