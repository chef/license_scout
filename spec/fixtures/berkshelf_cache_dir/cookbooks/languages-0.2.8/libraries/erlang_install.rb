#
# Cookbook Name:: languages
# HWRP:: erlang_install
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

require_relative 'language_install'

class Chef
  class Resource::ErlangInstall < Resource::LanguageInstall
    resource_name :erlang_install
  end
end

class Chef
  class Provider::ErlangInstall < Provider::LanguageInstall
    provides :erlang_install

    KERL_SHA = 'master'.freeze

    #
    # @see Chef::Resource::LanguageInstall#installed?
    #
    def installed?
      if ::File.exist?(::File.join(new_resource.prefix, 'bin', 'erl'))
        major_version = new_resource.version.split('.').first
        new_resource.version == ::File.read("#{new_resource.prefix}/releases/#{major_version}/OTP_VERSION").strip
      else
        false
      end
    end

    #
    # @see Chef::Resource::LanguageInstall#install_dependencies?
    #
    def install_dependencies
      super

      # ensure the destination directory exists
      kerl_directory = Resource::Directory.new(kerl_path, run_context)
      kerl_directory.recursive(true)
      kerl_directory.run_action(:create)

      # install kerl
      kerl_install = Chef::Resource::RemoteFile.new(::File.join(kerl_path, 'kerl'), run_context)
      kerl_install.source("https://raw.githubusercontent.com/kerl/kerl/#{KERL_SHA}/kerl")
      kerl_install.mode('0755')
      kerl_install.sensitive(true)
      kerl_install.run_action(:create)

      # update kerl's known versions
      kerl_update = Chef::Resource::Execute.new("#{kerl_path}/kerl update releases", run_context)
      kerl_update.run_action(:run)

      # drop off a .kerlrc file to tune various paths
      kerl_config = Chef::Resource::File.new(::File.join(kerl_path, '.kerlrc'), run_context)
      kerl_config.content(
        <<-EOH.gsub(/^ {10}/, '')
          KERL_DOWNLOAD_DIR=#{kerl_path}/archives
          KERL_BUILD_DIR=#{kerl_path}/builds
        EOH
      )
      kerl_config.sensitive(true)
      kerl_config.run_action(:create)
    end

    #
    # @see Chef::Resource::LanguageInstall#install
    #
    def install
      build_erlang
      install_erlang
    end

    private

    def kerl_path
      ::File.join(Chef::Config[:file_cache_path], "kerl-#{KERL_SHA}")
    end

    # Tricks `kerl` to looking for a `.kerlrc` file in Chef's cache
    def kerl_environment
      { 'HOME' => kerl_path }
    end

    def build_erlang
      build_erlang = Chef::Resource::Execute.new("#{kerl_path}/kerl build #{new_resource.version} #{new_resource.version}", run_context)
      build_erlang.environment(kerl_environment)
      build_erlang.run_action(:run)
    end

    def install_erlang
      install_erlang = Chef::Resource::Execute.new("#{kerl_path}/kerl install #{new_resource.version} #{new_resource.prefix}", run_context)
      install_erlang.environment(kerl_environment)
      install_erlang.run_action(:run)
    end
  end
end
