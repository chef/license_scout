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

#gem "rugged", "= 0.27" # Pin rugged to 0.27 as it breaks on windows https://github.com/libgit2/rugged/issues/791
gem 'rugged', '~> 1.0'
gem 'ostruct'
gem 'csv'
gem 'logger'
gem 'httpclient', '~> 2.7.0'
gem 'mutex_m'
gem 'ffi', '~> 1.15'
gem 'faraday', '~> 1.0'
gemspec

group :development do
  #gem "rake", "~> 10.0"
  gem 'rake', '~> 13.0'
  gem "rspec"
  gem "pry"
  gem "rb-readline"
  gem "chefstyle"
  gem "vcr"
  gem "webmock"
  gem "berkshelf", " ~> 4.3"
end
