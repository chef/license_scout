#
# Cookbook Name:: omnibus
# HWRP:: ruby_install
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

require_relative 'language_install'

class Chef
  class Resource::RubyInstall < Resource::LanguageInstall
    resource_name :ruby_install
  end

  class Provider::RubyInstall < Provider::LanguageInstall
    provides :ruby_install,
             platform_family: %w(
               aix
               debian
               freebsd
               mac_os_x
               rhel
               solaris2
             )

    RUBY_INSTALL_VERSION  = '0.4.1'.freeze
    RUBY_INSTALL_CHECKSUM = '1b35d2b6dbc1e75f03fff4e8521cab72a51ad67e32afd135ddc4532f443b730e'.freeze

    #
    # @see Chef::Resource::LanguageInstall#installed?
    #
    def installed?
      installed_at_version?(::File.join(new_resource.prefix, 'bin', 'ruby'), new_resource.version)
    end

    #
    # @see Chef::Resource::LanguageInstall#install_dependencies?
    #
    def install_dependencies
      super

      # install ruby-install
      return if Chef::Sugar::Shell.installed_at_version?("#{ruby_install_path}/bin/ruby-install", RUBY_INSTALL_VERSION)
      ruby_install = Chef::Resource::RemoteInstall.new('ruby-install', run_context)
      ruby_install.source("https://codeload.github.com/postmodern/ruby-install/tar.gz/v#{RUBY_INSTALL_VERSION}")
      ruby_install.version(RUBY_INSTALL_VERSION)
      ruby_install.checksum(RUBY_INSTALL_CHECKSUM)
      ruby_install.install_command('echo "nothing to install"')
      ruby_install.run_action(:install)
    end

    #
    # @see Chef::Resource::LanguageInstall#install
    #
    def install
      # Need to compile the command outside of the execute resource because
      # Ruby is bad at instance_eval
      install_command = "#{ruby_install_path}/bin/ruby-install --no-install-deps --install-dir #{new_resource.prefix}"

      patches.each do |p|
        install_command << " --patch #{p}"
      end

      install_command << " ruby #{new_resource.version} -- #{compile_flags}"

      install_ruby = Resource::Execute.new("install ruby-#{new_resource.version}", run_context)
      install_ruby.command(install_command)
      install_ruby.environment(environment)
      install_ruby.run_action(:run)

      # Ensure Bundler is installed
      install_bundler = Resource::Execute.new("#{new_resource.prefix}/bin/gem install bundler", run_context)
      install_bundler.environment(environment)
      install_bundler.run_action(:run)
    end

    private

    def ruby_install_path
      # This is the default location `remote_install` extracts a tarball to.
      # See the following for full details:
      #
      # https://github.com/chef-cookbooks/remote_install/blob/bea400cea43433165a6b6be74ea8544db212f080/libraries/remote_install.rb#L35-L36
      # https://github.com/chef-cookbooks/remote_install/blob/bea400cea43433165a6b6be74ea8544db212f080/libraries/remote_install.rb#L97
      #
      ::File.join(Chef::Config[:file_cache_path], "ruby-install-#{RUBY_INSTALL_VERSION}")
    end

    def environment
      build_env = {}

      #
      # Taken from the omnibus-software/ruby
      #
      #   https://github.com/chef/omnibus-software/blob/38e8befd5ecd14b7ad32c4bd3118fe4caf79ee92/config/software/ruby.rb
      #
      if solaris_11?
        build_env['CC']   = '/usr/sfw/bin/gcc'
        build_env['MAKE'] = 'gmake'

        if sparc?
          build_env['CFLAGS']  = '-O0 -g -pipe -mcpu=v9'
          build_env['LDFLAGS'] = '-mcpu=v9'
        end
      end

      build_env
    end

    def compile_flags
      [
        '--disable-install-rdoc',
        '--disable-install-ri',
        '--with-out-ext=tcl',
        '--with-out-ext=tk',
        '--without-tcl',
        '--without-tk',
        '--disable-dtrace',
      ].join(' ')
    end

    def patches
      patches = []

      #
      # Taken from the omnibus-software/ruby
      #
      #   https://github.com/chef/omnibus-software/blob/38e8befd5ecd14b7ad32c4bd3118fe4caf79ee92/config/software/ruby.rb
      #
      if solaris_11?
        patches << 'https://raw.githubusercontent.com/chef/omnibus-software/38e8befd5ecd14b7ad32c4bd3118fe4caf79ee92/config/patches/ruby/ruby-solaris-linux-socket-compat.patch'
      end

      patches
    end
  end

  class Provider::RubyInstallWindows < Provider::LanguageInstall
    include Languages::Helper

    provides :ruby_install, platform_family: 'windows'

    #
    # @see Chef::Resource::LanguageInstall#installed?
    #
    def installed?
      ::File.exist?(::File.join(new_resource.prefix, 'bin', 'ruby.exe'))
    end

    #
    # @see Chef::Resource::LanguageInstall#install_dependencies
    #
    def install_dependencies
      # nothing to do here
    end

    #
    # @see Chef::Resource::LanguageInstall#install
    #
    def install
      ruby_installer = Resource::RemoteFile.new("fetch ruby-#{new_resource.version}", run_context)
      ruby_installer.path(installer_download_path)
      ruby_installer.source(installer_url)
      ruby_installer.backup(false)
      ruby_installer.run_action(:create)

      install_command = %(#{installer_download_path} /verysilent /dir="#{new_resource.prefix}" /tasks="assocfiles")

      execute = Resource::Execute.new("install ruby-#{new_resource.version}", run_context)
      execute.command(install_command)
      execute.run_action(:run)

      install_devkit
      configure_ca
      install_bundler
    end

    private

    # Installs the DevKit in the Ruby so we can compile gems with native extensions.
    def install_devkit
      devkit = Resource::RemoteFile.new("fetch devkit for ruby-#{new_resource.version}", run_context)
      devkit.path(devkit_download_path)
      devkit.source(devkit_url)
      devkit.backup(false)
      devkit.run_action(:create)

      # Generate config.yml which is used by DevKit install
      require 'yaml'
      config_yml = Resource::File.new(windows_safe_path_join(new_resource.prefix, 'config.yml'), run_context)
      config_yml.content([new_resource.prefix].to_yaml)
      config_yml.run_action(:create)

      install_command = %(#{devkit_download_path} -y -o"#{new_resource.prefix}" & "#{ruby_bin}" dk.rb install)

      execute = Resource::Execute.new("install devkit for ruby-#{new_resource.version}", run_context)
      execute.command(install_command)
      execute.cwd(new_resource.prefix)
      execute.run_action(:run)
    end

    #
    # Ensures a certificate authority is available and configured. See:
    #
    #   https://gist.github.com/fnichol/867550
    #
    def configure_ca
      certs_dir = Resource::Directory.new(ssl_certs_dir, run_context)
      certs_dir.recursive(true)
      certs_dir.run_action(:create)

      cacerts = Resource::CookbookFile.new("install cacerts bundle for ruby-#{new_resource.version}", run_context)
      cacerts.path(cacert_file)
      cacerts.source('cacert.pem')
      cacerts.cookbook('languages')
      cacerts.backup(false)
      cacerts.sensitive(true)
      cacerts.run_action(:create)
    end

    def install_bundler
      gem_bin = windows_safe_path_join(new_resource.prefix, 'bin', 'gem')
      execute = Resource::Execute.new("#{gem_bin} install bundler", run_context)
      execute.environment('SSL_CERT_FILE' => cacert_file)
      execute.run_action(:run)
    end

    def installer_url
      "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-#{new_resource.version}.exe"
    end

    def installer_download_path
      windows_safe_path_join(Chef::Config[:file_cache_path], ::File.basename(installer_url))
    end

    # Determines the proper version of the DevKit based on Ruby version.
    def devkit_url
      # 2.0 64-bit
      if new_resource.version =~ /^2\.\d\.\d.*x64$/
        'http://cdn.rubyinstaller.org/archives/devkits/DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe'
      # 2.0 32-bit
      elsif new_resource.version =~ /^2\.\d\.\d.*$/
        'http://cdn.rubyinstaller.org/archives/devkits/DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe'
      # Ruby 1.8.7 and 1.9.3
      else
        'https://github.com/downloads/oneclick/rubyinstaller/DevKit-tdm-32-4.5.2-20111229-1559-sfx.exe'
      end
    end

    def devkit_download_path
      windows_safe_path_join(Chef::Config[:file_cache_path], ::File.basename(devkit_url))
    end

    def ruby_bin
      windows_safe_path_join(new_resource.prefix, 'bin', 'ruby')
    end

    def ssl_certs_dir
      windows_safe_path_join(new_resource.prefix, 'ssl', 'certs')
    end

    def cacert_file
      windows_safe_path_join(ssl_certs_dir, 'cacert.pem')
    end
  end
end
