#
# Copyright:: Copyright 2016, Chef Software Inc.
# License:: Apache License, Version 2.0
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

require "license_scout/options"

RSpec.describe(LicenseScout::Options) do

  subject(:options) do
    described_class.new(input_parameters)
  end

  let(:input_parameters) { {} }

  it "has an option for overrides with default of an Overrides class" do
    o = options.overrides
    expect(o).to be_a(LicenseScout::Overrides)
    expect(o.license_for("ruby_bundler", "sfl", "1.0.0")).to eq("Ruby")
  end

  it "has an option for environment with default of empty hash" do
    expect(options.environment).to eq({})
  end

  it "has an option for ruby_bin with default of nil" do
    expect(options.ruby_bin).to eq(nil)
  end

  context "with :overrides input" do
    let(:input_parameters) do
      {
        overrides: LicenseScout::Overrides.new do
          override_license "special_packager", "chef" do |version|
            {
              license: "CUSTOM",
            }
          end
        end,
      }
    end

    it "can set the overrides" do
      expect(options.overrides.license_for("special_packager", "chef", "1.0.0")).to eq("CUSTOM")
    end
  end

  context "with :environment input" do
    let(:input_parameters) do
      {
        environment: {
          "PATH" => "/path/to/happiness",
        },
      }
    end

    it "can set the environment" do
      expect(options.environment["PATH"]).to eq("/path/to/happiness")
    end
  end

  context "with :ruby_bin input" do
    let(:input_parameters) do
      {
        ruby_bin: "c:/opscode/chef/embedded/bin/ruby",
      }
    end

    it "can set the ruby_bin" do
      expect(options.ruby_bin).to eq("c:/opscode/chef/embedded/bin/ruby")
    end
  end

  context "with :manual_licenses input" do
    let(:input_parameters) do
      {
        manual_licenses: [
          {
            license: "MIT",
          },
        ],
      }
    end

    it "can set the manual_licenses" do
      expect(options.manual_licenses.first[:license]).to eq("MIT")
    end
  end

end
