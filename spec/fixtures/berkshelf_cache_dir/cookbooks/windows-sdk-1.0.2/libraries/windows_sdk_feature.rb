class WindowsSdkCookbook
  class Resource
    class Feature < Chef::Resource
      provides :windows_sdk_feature, os: "windows"

      def initialize(name, run_context=nil)
        super
        @resource_name = :windows_sdk_feature
        @action = :install
        @allowed_actions.push(:install, :uninstall)
        features(name)
      end

      def features(arg=nil)
        if arg.nil?
          @features
        else
          if arg.is_a?(Array)
            @features = arg
          else
            if arg == :all
              @features = WindowsSdkCookbook::Helpers::AVAILABLE_FEATURES.keys
            else
              @features = [arg]
            end
          end
        end
      end

      def version(arg=nil)
        set_or_return(
          :version,
          arg,
          :kind_of => [String]
        )
      end

      def install_path(arg=nil)
        set_or_return(
          :install_path,
          arg,
          :kind_of => [String]
        )
      end
    end
  end

  class Provider < Chef::Provider
    provides :windows_sdk_feature, os: "windows"

    def whyrun_supported?
      true
    end

    def load_current_resource
      versions = new_resource.features.map do |f|
        WindowsSdkCookbook::Helpers.validate_feature!(f)

        info = WindowsSdkCookbook::Helpers.installed_version(f)
        if info.nil?
          Chef::Log.debug("#{f} is not yet installed for the Windows SDK")
        else
          Chef::Log.debug("Detected #{f} is installed with version #{info["Version"]}")
        end
        info
      end
      @installed_versions = @new_resource.features.zip(versions)
    end

    def action_install
      to_install = @installed_versions.select do |feature|
        # Downgrades are not supported
        if feature[1] == nil
          true
        elsif feature[0] == :netfx_software_development_kit
          Gem::Version.new(feature[1]['Version']) < Gem::Version.new(WindowsSdkCookbook::Helpers::AVAILABLE_VERSIONS[requested_version.to_s][:netfx_version])
        else
          v = Gem::Version.new(feature[1]['Version'])
          v.segments[0] < requested_version.segments[0] || (
            v.segments[0] == requested_version.segments[0] && v.segments[1] < requested_version.segments[1])
        end
      end

      if to_install.length > 0
        remote_resource.run_action(:create)

        all_features = to_install.map do |feature|
          WindowsSdkCookbook::Helpers.flag_for_feature(feature[0])
        end.join(' ')

        converge_by "Installing Windows SDK Features #{all_features}" do
          args = Array.new.tap do |args|
            args << "\"#{remote_resource.path}\""
            args << "/norestart"
            args << "/quiet"
            args << "/installpath \"#{new_resource.install_path}\"" if new_resource.install_path
            args << "/features #{all_features}"
          end
          shell_out!(args.join(" "))
        end
      end
    end

    def action_uninstall
      if @installed_versions.length > 0
        all_features = @installed_versions.map do |feature|
          WindowsSdkCookbook::Helpers.flag_for_feature(feature[0])
        end.join(' ')

        converge_by "Uninstalling Windows SDK Features #{all_features}" do
          shell_out!("\"#{remote_resource.path}\" /quiet /uninstall /features #{all_features}")
        end
      end
    end

    private

    def remote_resource
      @remote_resource ||= Chef::Resource::RemoteFile.new(default_download_cache_path,
                                                          run_context).tap do |r|
        r.source(WindowsSdkCookbook::Helpers::AVAILABLE_VERSIONS[requested_version.to_s][:url])
      end
    end

    def default_download_cache_path
      file_cache_dir = Chef::FileCache.create_cache_path("package/")
      Chef::Util::PathHelper.cleanpath("#{file_cache_dir}/sdksetup-#{requested_version}.exe")
    end

    def requested_version
      @requested_version ||= begin
        v = new_resource.version || WindowsSdkCookbook::Helpers::AVAILABLE_VERSIONS.keys[0]
        Gem::Version.new(v)
      end
    end

  end
end
