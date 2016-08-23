#
# Cookbook Name:: languages
# HWRP:: node_install
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
  class Resource::NodeInstall < Resource::LanguageInstall
    resource_name :node_install
  end

  class Provider::NodeInstall < Provider::LanguageInstall
    provides :node_install

    NVM_VERSION  = '0.29.0'.freeze
    NVM_CHECKSUM = '04f6f2710bc3b3820cde1055e735a6cd8fa71a3c9c2881c49c8653e982e0d86a'.freeze

    #
    # @see Chef::Resource::LanguageInstall#installed?
    #
    def installed?
      installed_at_version?(::File.join(new_resource.prefix, 'bin', 'node'), new_resource.version)
    end

    #
    # @see Chef::Resource::LanguageInstall#install_dependencies?
    #
    def install_dependencies
      super

      package 'tar' if debian? || rhel?

      return if Chef::Sugar::Shell.installed_at_version?('. #{nvm_path}/nvm.sh && nvm --version', NVM_VERSION)
      nvm_install = Chef::Resource::RemoteInstall.new('nvm', run_context)
      nvm_install.source("https://codeload.github.com/creationix/nvm/tar.gz/v#{NVM_VERSION}")
      nvm_install.version(NVM_VERSION)
      nvm_install.checksum(NVM_CHECKSUM)
      nvm_install.install_command('echo "nothing to install"')
      nvm_install.run_action(:install)
    end

    #
    # @see Chef::Resource::LanguageInstall#install
    #
    def install
      build_node
      install_node
    end

    private

    def nvm_path
      # This is the default location `remote_install` extracts a tarball to.
      # See the following for full details:
      #
      # https://github.com/chef-cookbooks/remote_install/blob/bea400cea43433165a6b6be74ea8544db212f080/libraries/remote_install.rb#L35-L36
      # https://github.com/chef-cookbooks/remote_install/blob/bea400cea43433165a6b6be74ea8544db212f080/libraries/remote_install.rb#L97
      #
      ::File.join(Chef::Config[:file_cache_path], "nvm-#{NVM_VERSION}")
    end

    def build_node
      build_node = Resource::Execute.new("build node-#{new_resource.version}", run_context)
      build_node.command(". #{nvm_path}/nvm.sh && nvm install #{new_resource.version}")
      build_node.cwd(nvm_path)
      build_node.environment(
        'NVM_DIR' => nvm_path,
      )
      build_node.run_action(:run)
    end

    def install_node
      # ensure the destination directory exists
      node_directory = Resource::Directory.new(new_resource.prefix, run_context)
      node_directory.recursive(true)
      node_directory.run_action(:create)

      # copy the NodeJS that nvm compiled (or extracted) into place
      node_build_path = shell_out!(". #{nvm_path}/nvm.sh && nvm_version_path #{new_resource.version}", env: { 'NVM_DIR' => nvm_path }).stdout.strip
      FileUtils.cp_r("#{node_build_path}/.", "#{new_resource.prefix}/")
    end
  end
end
