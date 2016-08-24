#
# Cookbook Name:: opscode-ci
# HWRP:: rust_install
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

class Chef
  class Resource::RustInstall < Resource::LanguageInstall
    resource_name :rust_install

    attribute :channel,
              kind_of: String,
              equal_to: %w( stable beta nightly ),
              default: 'stable'
  end
end

class Chef
  class Provider::RustInstall < Provider::LanguageInstall
    provides :rust_install,
             platform_family: %w(
               aix
               debian
               freebsd
               mac_os_x
               rhel
               solaris2
             )

    #
    # @see Chef::Resource::LanguageInstall#installed?
    #
    def installed?
      installed_at_version?(::File.join(new_resource.prefix, 'bin', 'rustc'), new_resource.version)
    end

    #
    # @see Chef::Resource::LanguageInstall#install_dependencies?
    #
    def install_dependencies
      super

      # install the rustup script
      rustup_install = Resource::RemoteFile.new(rustup_path, run_context)
      rustup_install.source('https://static.rust-lang.org/rustup.sh')
      rustup_install.mode('0755')
      rustup_install.sensitive(true)
      rustup_install.run_action(:create)
    end

    #
    # @see Chef::Resource::LanguageInstall#install
    #
    def install
      install_rust = Resource::Execute.new("install rust-#{new_resource.version}", run_context)
      install_rust.command("#{rustup_path} #{rustup_flags}")
      install_rust.run_action(:run)

      # create ldconfig file
      ldconfig_conf = Chef::Resource::File.new("/etc/ld.so.conf.d/rust-#{new_resource.version}.conf", run_context)
      ldconfig_conf.content(::File.join(new_resource.prefix, 'lib'))
      ldconfig_conf.sensitive(true)
      ldconfig_conf.run_action(:create)

      # update ldconfig cache
      ldconfig_update = Resource::Execute.new('ldconfig', run_context)
      ldconfig_update.run_action(:run)
    end

    private

    def rustup_path
      ::File.join(Chef::Config[:file_cache_path], 'rustup.sh')
    end

    def rustup_flags
      flags = [
        "--prefix=#{new_resource.prefix}",
        # `sudo` causes issues on EL7 and CCRs should already be
        # run with elevated privileges.
        '--disable-sudo',
        '--yes',
      ]

      if new_resource.version =~ /\d{4}-\d{2}-\d{2}/
        flags << "--channel=#{new_resource.channel}"
        flags << "--date=#{new_resource.version}"
      else
        flags << "--revision=#{new_resource.version}"
      end

      flags.join(' ')
    end
  end

  class Provider::RustInstallWindows < Provider::RustInstall
    provides :rust_install, platform_family: 'windows'

    #
    # @see Chef::Resource::LanguageInstall#installed?
    #
    def installed?
      ::File.exist?(::File.join(new_resource.prefix, 'bin', 'rustc.exe'))
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
      rust_installer = Resource::WindowsPackage.new('rust', run_context)
      rust_installer.source(installer_url)
      rust_installer.options(installer_options)
      rust_installer.run_action(:install)
    end

    private

    def installer_options
      [
        'ADDLOCAL=Rustc,Gcc,Docs,Cargo,Path',
        "INSTALLDIR=#{windows_safe_path_expand(new_resource.prefix)}",
      ].join(' ')
    end

    def installer_url
      if new_resource.version =~ /\d{4}-\d{2}-\d{2}/
        "https://static.rust-lang.org/dist/#{new_resource.version}/rust-#{new_resource.channel}-x86_64-pc-windows-gnu.msi"
      else
        "https://static.rust-lang.org/dist/rust-#{new_resource.version}-x86_64-pc-windows-gnu.msi"
      end
    end
  end
end
