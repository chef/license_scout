require 'csv'

class WindowsSdkCookbook
  class Helpers
    extend Chef::Mixin::ShellOut

    unless defined? AVAILABLE_FEATURES
      AVAILABLE_FEATURES = {
        windows_software_development_kit: {
          uid: '{984022F2-9BCA-A41D-6A38-1AE658F01415}',
          flag: 'WindowsDesktopSoftwareDevelopmentKit'
        },
        windows_performance_toolkit: {
          uid: '{BFF81CB5-E8C7-4184-FBB4-74ADFBC6CCCB}',
          flag: 'WindowsPerformanceToolkit'
        },
        debugging_tools: {
          uid: '{9274C832-3D8A-A294-FDE8-8B9272357098}',
          flag: 'WindowsDesktopDebuggers'
        },
        application_verifier: {
          uid: '{77F3D72C-465F-BD51-890E-CC3914B1365F}',
          flag: 'AvrfExternal'
        },
        windows_app_certification_kit: {
          uid: '{F395FD4F-40E5-7B56-2BCB-B3CF52B3B52C}',
          flag: 'WindowsSoftwareLogoToolkit'
        },
        msi_tools: {
          uid: '{CF3A1CA6-5E5E-B4BD-6CF1-363056816CA2}',
          flag: 'MSIInstallTools'
        },
        netfx_software_development_kit: {
          uid: '{19A5926D-66E1-46FC-854D-163AA10A52D3}',
          flag: 'NetFxSoftwareDevelopmentKit'
        }
      }
    end

    unless defined? AVAILABLE_VERSIONS
      AVAILABLE_VERSIONS = {
        '8.100.26936' => {
          netfx_version: '4.5.51641',
          url: 'http://download.microsoft.com/download/B/0/C/B0C80BA3-8AD6-4958-810B-6882485230B5/standalonesdk/sdksetup.exe'
        }
      }
    end

    def self.validate_feature!(feature_name)
      raise "Invalid feature #{feature_name}. You must pick from "\
        "#{AVAILABLE_FEATURES.join(',')}" unless AVAILABLE_FEATURES.include?(feature_name)
    end

    def self.installed_version(feature_name)
      command = "Get-WmiObject -class Win32_Product "\
        "| Where-Object {$_.IdentifyingNumber -eq '#{uid_for_feature(feature_name)}'} "\
        "| Select-Object IdentifyingNumber, Name, Version | ConvertTo-CSV -NoTypeInformation"
      stdout = powershell_out!(command)
      info = CSV.parse(stdout.strip, :headers => :first_line)
      if info.length == 0
        nil
      else
        Hash[info[0]]
      end
    end

    def self.uid_for_feature(feature_name)
      AVAILABLE_FEATURES[feature_name][:uid]
    end

    def self.flag_for_feature(feature_name)
      "OptionId.#{AVAILABLE_FEATURES[feature_name][:flag]}"
    end

    def self.install_args(sdksetup_exe, features)
      "/features #{features.map(&:flag_for_feature).join(" ")}"
    end

    def self.powershell_out!(cmd)
      Dir::Tmpname.create('windows-sdk-cmdlet') do |path|
        shell_out!("powershell.exe -NoLogo -NonInteractive -NoProfile -ExecutionPolicy Unrestricted -InputFormat None -Command \"#{cmd}\" > #{path}")
        File.read(path)
      end
    end
  end
end
