#
# Copyright 2015, Chef Software, Inc.
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

require_relative '_helper'
require_relative '_prefix'

class Chef
  class Resource::LanguageExecute < Resource::LWRPBase
    include Languages::Prefix

    actions :run
    default_action :run

    attribute :command, kind_of: String, name_attribute: true
    attribute :version, kind_of: String, required: true
    attribute :prefix, kind_of: String, default: lazy { |r| r.default_prefix(r.version) }

    # Useful attributes from the `execute` resource that might need overriding
    attribute :cwd, kind_of: String
    attribute :environment, kind_of: Hash, default: {}
    attribute :user, kind_of: [String, Integer]
    attribute :returns, kind_of: [Integer, Array], default: 0
    attribute :sensitive, kind_of: [TrueClass, FalseClass], default: false
  end

  class Provider::LanguageExecute < Provider::LWRPBase
    include Languages::Helper

    def whyrun_supported?
      true
    end

    action(:run) do
      converge_by("run #{new_resource}") do
        with_clean_env do
          execute_resource = Resource::Execute.new(new_resource.command, run_context)
          execute_resource.environment(environment)

          # Pass through some default attributes for the `execute` resource
          execute_resource.cwd(new_resource.cwd)
          execute_resource.user(new_resource.user)
          execute_resource.sensitive(new_resource.sensitive)
          execute_resource.live_stream(true) if execute_resource.respond_to?(:live_stream)
          execute_resource.run_action(:run)
        end
      end
    end

    #
    # Environment used to execute a command in the context of a particular
    # language install. At a minimum this method ensures the language bin
    # directory is first in the `PATH`.
    #
    # @return [Hash]
    #
    def environment
      environment = new_resource.environment || {}
      # ensure we don't clobber a `PATH` value set by the user
      existing_path = environment.delete('PATH')
      environment['PATH'] = [language_path, existing_path, ENV['PATH']].compact.join(::File::PATH_SEPARATOR)
      environment['Path'] = environment['PATH'] if Chef::Platform.windows?
      environment
    end

    def language_path
      if Chef::Platform.windows?
        windows_safe_path_join(new_resource.prefix, 'bin')
      else
        ::File.join(new_resource.prefix, 'bin')
      end
    end
  end
end
