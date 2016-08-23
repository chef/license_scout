#
# Cookbook Name:: languages
# HWRP:: rust_execute
#
# Copyright 2015, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'language_execute'

class Chef
  class Resource::RustExecute < Resource::LanguageExecute
    resource_name :rust_execute
  end

  class Provider::RustExecute < Provider::LanguageExecute
    provides :rust_execute

    #
    # @see Chef::Resource::LanguageExecute#environment
    #
    def environment
      environment = super
      # We run `ldconfig` when Rust is installed but we'll go ahead and
      # set `LD_LIBRARY_PATH` just to be safe.
      environment['LD_LIBRARY_PATH'] = ::File.join(new_resource.prefix, 'lib')
      environment
    end
  end
end
