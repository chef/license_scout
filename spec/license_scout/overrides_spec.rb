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

require "license_scout/overrides"

RSpec.describe(LicenseScout::Overrides::OverrideLicenseSet) do

  let(:override_license_set) { described_class.new(license_locations) }

  let(:dep_dir) { File.join(SPEC_FIXTURES_DIR, "test_licenses") }

  context "when created with an empty array" do

    let(:license_locations) { [] }

    it "has no license locations" do
      expect(override_license_set.license_locations).to eq([])
    end

    it "resolves the license locations to an empty array" do
      expect(override_license_set.resolve_locations(dep_dir)).to eq([])
    end

    it "is empty" do
      expect(override_license_set).to be_empty
    end
  end

  context "when created with nil" do

    let(:license_locations) { nil }

    it "has no license locations" do
      expect(override_license_set.license_locations).to eq([])
    end

    it "resolves the license locations to an empty array" do
      expect(override_license_set.resolve_locations(dep_dir)).to eq([])
    end

    it "is empty" do
      expect(override_license_set).to be_empty
    end
  end

  context "when created with a license location" do

    context "when override license files are relative paths" do

      context "and the license exists" do

        let(:license_locations) { [ "BSD-LICENSE" ] }

        it "resolves the full path to the license" do
          expected_path = File.join(dep_dir, "BSD-LICENSE")
          expect(override_license_set.resolve_locations(dep_dir)).to eq( [ expected_path ] )
        end

      end

      context "and the license file doesn't exist" do

        let(:license_locations) { [ "NOPE-LICENSE" ] }

        it "raises InvalidOverride" do
          expect { override_license_set.resolve_locations(dep_dir) }.
            to raise_error(LicenseScout::Exceptions::InvalidOverride)
        end

      end

    end

    context "when override license files are remote" do

      let(:url) { "https://content.example/project/LICENSE.txt" }

      let(:cache_path) { "/var/cache/licenses/foo/LICENSE.txt" }

      let(:license_locations) { [ url ] }

      it "fetches the license file from the web and gives the cached path" do
        expect(LicenseScout::NetFetcher).to receive(:cache).with(url).and_return(cache_path)
        expect(override_license_set.resolve_locations(dep_dir)).to eq([cache_path])
      end

    end
  end
end

RSpec.describe(LicenseScout::Overrides) do

  subject(:overrides) do
    LicenseScout::Overrides.new() do
      override_license "test_dep_manager", "example1" do |version|
        {
          license: "BSD",
          license_files: [ "BSD-LICENSE" ],
        }
      end
    end
  end

  it "contains default overrides for ruby_bundler" do
    expect(overrides.license_for("ruby_bundler", "pry-remote", "1.0.0")).to eq("MIT")
  end

  context "when an override exists for a dependency" do
    it "finds the license for a given dependency manager, dep name, and dep version" do
      expect(overrides.license_for("test_dep_manager", "example1", "1.0.0")).to eq("BSD")
    end

    it "finds the license files for a given dep manager name, dep name and dep version" do
      set = overrides.license_files_for("test_dep_manager", "example1", "1.0.0")
      expect(set.license_locations).to eq(["BSD-LICENSE"])
    end

  end

  context "when an override doesn't exist for a dependency" do
    it "returns nil for the dependency's license" do
      expect(overrides.license_for("test_dep_manager", "example99", "1.0.0")).to eq(nil)
    end

    it "returns an empty license set" do
      expect(overrides.license_files_for("test_dep_manager", "example99", "1.0.0")).to be_empty
    end
  end

  context "when no overrides exist for the given dependency manager" do
    it "returns nil for the dependency's license" do
      expect(overrides.license_for("nope_dep_manager", "example99", "1.0.0")).to eq(nil)
    end

    it "return an empty array for the dependency's license files" do
      expect(overrides.license_files_for("nope_dep_manager", "example99", "1.0.0")).to be_empty
    end
  end

  describe "#default_overrides" do
    let(:overrides) { LicenseScout::Overrides.new() }

    it "doesn't pull license info from non-raw github URLs" do
      overrides.override_rules.each do |dep_manager, library_map|
        library_map.each_key do |library_name|
          license_files = overrides.license_files_for(dep_manager, library_name, nil)
          if license_files.license_locations.any? { |location| location.include?("(\/\/|www\.)github.com") }
            fail "You must use raw.githubusercontent.com instead of github.com for overrides. \n" +
                 "Dependency type: #{dep_manager}\nDependency name: #{library_name}\nLicense location: #{license_files.license_locations}"
          end
        end
      end
    end
  end
end
