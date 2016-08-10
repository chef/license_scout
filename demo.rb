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
    # Internet overrides
    ["sfl", "Ruby", ["https://raw.githubusercontent.com/ujihisa/spawn-for-legacy/master/LICENCE.md"]],
    ["json_pure", nil, ["https://raw.githubusercontent.com/flori/json/master/README.md"]],
    ["aws-sdk-core", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
    ["aws-sdk-resources", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
    ["aws-sdk", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
    ["fuzzyurl", nil, ["https://raw.githubusercontent.com/gamache/fuzzyurl/master/LICENSE.txt"]],
    ["jwt", nil, ["https://github.com/jwt/ruby-jwt/blob/master/LICENSE"]],
  ].each do |override_data|
    override_license "ruby_bundler", override_data[0] do |version|
      {}.tap do |d|
        d[:license] = override_data[1] if override_data[1]
        d[:license_files] = override_data[2] if override_data[2]
      end
    end
  end
end

collector = LicenseScout::Collector.new("chef", chef_directory, output_directory, overrides)
collector.run
puts collector.issue_report.join("\n")
