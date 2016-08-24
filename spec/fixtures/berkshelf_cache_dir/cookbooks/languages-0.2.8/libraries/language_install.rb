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
  class Resource::LanguageInstall < Resource::LWRPBase
    include Languages::Prefix

    actions :install
    default_action :install

    attribute :version, kind_of: String, name_attribute: true, required: true
    attribute :prefix,  kind_of: String, default: lazy { |r| r.default_prefix(r.version) }
  end

  class Provider::LanguageInstall < Provider::LWRPBase
    include Languages::Helper

    def whyrun_supported?
      true
    end

    action(:install) do
      if installed?
        Chef::Log.debug("#{new_resource} installed - skipping")
      else
        converge_by("install #{new_resource}") do
          install_dependencies
          install
        end
      end
    end

    #
    # Determines if a language is installed at a particular version.
    #
    # @return [Boolean]
    #
    def installed?
      raise NotImplementedError
    end

    #
    # Installs required dependencies required to compile or extract a
    # a language.
    #
    def install_dependencies
      recipe_eval do
        run_context.include_recipe 'chef-sugar::default'
        run_context.include_recipe 'build-essential::default'

        case node.platform_family
        when 'debian'
          package 'curl'
          package 'git-core'
          package 'libxml2-dev'
          package 'libxslt-dev'
          package 'zlib1g-dev'
          package 'ncurses-dev'
          package 'libssl-dev'
        when 'freebsd'
          package 'textproc/libxml2'
          package 'textproc/libxslt'
          package 'devel/ncurses'
        when 'mac_os_x'
          run_context.include_recipe 'homebrew::default'
          package 'libxml2'
          package 'libxslt'
          package 'openssl'
        when 'rhel'
          package 'curl'
          package 'bzip2'
          package 'file'
          package 'git'
          package 'libxml2-devel'
          package 'libxslt-devel'
          package 'ncurses-devel'
          package 'zlib-devel'
          package 'openssl-devel'
        end
      end
    end

    #
    # Performs the actual install of a language.
    #
    def install
      raise NotImplementedError
    end
  end
end
