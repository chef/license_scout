require "license_scout/overrides"
require "license_scout/collector"

chef_directory = File.join(File.dirname(__FILE__), "../chef")
output_directory = File.join(File.dirname(__FILE__), "../chef_licenses")

overrides = LicenseScout::Overrides.new do

  [
    # [name, license, [license_file,...]]
    ["debug_inspector", "MIT", ["README.md"]],
    ["inifile", "MIT", ["README.md"]],
    ["syslog-logger", "MIT", ["README.rdoc"]],
    ["httpclient", "Ruby", ["README.md"]],
    ["little-plugger", "MIT", ["README.rdoc"]],
    ["logging", "MIT", ["README.md"]],
    ["coderay", nil, ["README_INDEX.rdoc"]],
    ["multipart-post", "MIT", ["README.md"]],
    ["erubis", "MIT", nil],
    ["binding_of_caller", "MIT", nil],
    ["method_source", "MIT", nil],
    ["pry-remote", "MIT", nil],
    ["pry-stack_explorer", "MIT", nil],
    ["plist", "MIT", nil],
    ["proxifier", "MIT", nil],
    ["mixlib-shellout", "Apache-2.0", nil],
    ["mixlib-log", "Apache-2.0", nil],
    ["uuidtools", "Apache-2.0", nil],
    ["cheffish", "Apache-2.0", nil],
    ["chef-provisioning", "Apache-2.0", nil],
    ["chef-provisioning-aws", "Apache-2.0", nil],
    ["chef-rewind", "MIT", nil],
    ["ubuntu_ami", "Apache-2.0", nil],
    ["net-telnet", "Ruby", nil],
  ].each do |override_data|
    override_license "ruby_bundler", override_data[0] do |version|
      {}.tap do |d|
        d[:license] = override_data[1] if override_data[1]
        d[:license_files] = override_data[2] if override_data[2]
      end
    end
  end

  # sfl, https://github.com/ujihisa/spawn-for-legacy/blob/master/LICENCE.md
  # json_pure, https://github.com/flori/json/blob/master/README.md
  # aws-sdk-core, aws-sdk-resources, aws-sdk
  #   https://github.com/aws/aws-sdk-ruby/blob/master/README.md
  #   http://www.apache.org/licenses/LICENSE-2.0.html
  # fuzzyurl, https://github.com/gamache/fuzzyurl/blob/master/LICENSE.txt
  # jwt, https://github.com/jwt/ruby-jwt/blob/master/LICENSE
end

collector = LicenseScout::Collector.new("chef", chef_directory, output_directory, overrides)
collector.run
puts collector.issue_report
