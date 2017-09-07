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

require "license_scout/dependency_manager/npm"
require "license_scout/overrides"
require "license_scout/options"

RSpec.describe(LicenseScout::DependencyManager::NPM) do

  subject(:npm) do
    described_class.new(project_dir, LicenseScout::Options.new(
      overrides: overrides
    ))
  end

  let(:overrides) { LicenseScout::Overrides.new(exclude_default: true) }

  let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "npm") }

  it "has a name" do
    expect(npm.name).to eq("js_npm")
  end

  it "has a project directory" do
    expect(npm.project_dir).to eq(project_dir)
  end

  describe "when run in a non-npm project dir" do

    let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "no_dependency_manager") }

    it "does not detect the project" do
      expect(npm.detected?).to eq(false)
    end

  end

  describe "when run in a npm project dir" do

    it "does detects the project" do
      expect(npm.detected?).to eq(true)
    end

    # npm recursively nests dependencies, make sure we find them.
    it "detects all transitive dependencies" do
      expect(npm.dependencies.size).to eq(102)

      # spec/fixtures/npm/node_modules/node-sass/node_modules/meow/package.json
      meow = npm.dependencies.find { |d| d.name == "meow" }
      expect(meow).to_not be_nil
    end

    it "dedups dependencies only if they are the same version" do
      dependencies = npm.dependencies
      minimist_info = dependencies.select { |d| d.name == "minimist" }
      minimist_info.sort! { |a, b| a.version <=> b.version }

      # There are 4 copies of minimist at different versions, after de-dup
      # on version there should only be 3. (`find spec/fixtures/npm -name minimist`)
      expect(minimist_info.size).to eq(3)
      expect(minimist_info[0].version).to eq("0.0.10")
      expect(minimist_info[1].version).to eq("0.0.8")
      expect(minimist_info[2].version).to eq("1.2.0")
    end

    it "detects dependencies with license files and license metadata" do
      angular = npm.dependencies.find { |d| d.name == "angular" }
      expect(angular.version).to eq("1.4.12")
      expect(angular.license).to eq("MIT")
      expected_license_path = File.join(SPEC_FIXTURES_DIR, "npm/node_modules/angular/LICENSE.md")
      expect(angular.license_files).to eq([expected_license_path])
    end

    # rc 1.1.6
    it "handles licenses with multiple license options" do
      rc_1_1_6 = npm.dependencies.find do |d|
        d.name == "rc" && d.version == "1.1.6"
      end

      # RC lets you pick any of these:
      # BSD-2-Clause OR MIT OR Apache-2.0
      #
      # We choose Apache 2.0 because it's what we use for our own stuff.
      expect(rc_1_1_6.license).to eq("Apache-2.0")
    end

    # The SPDX license format that npm uses allows packages to specify multiple
    # conjoined licenses, like "MIT AND CC-BY-3.0". Since this is based on a
    # standard syntax, we just pass it through, and let higher level tooling
    # (like omnibus) decide how to handle it.
    it "handles licenses with multiple combined license terms" do
      spdx_expression_parse = npm.dependencies.find do |d|
        d.name == "spdx-expression-parse"
      end
      expect(spdx_expression_parse.version).to eq("1.0.3")
      expect(spdx_expression_parse.license).to eq("MIT AND CC-BY-3.0")
    end

    it "detects dependencies with license metadata but no license files" do
      assert_plus_1_0_0 = npm.dependencies.find do |d|
        d.name == "assert-plus" && d.version = "1.0.0"
      end
      expect(assert_plus_1_0_0.license).to eq("MIT")
      expect(assert_plus_1_0_0.license_files).to eq([])
    end

    it "detects dependencies with license files but no metadata" do
      asn1 = npm.dependencies.find do |d|
        d.name == "asn1" && d.version == "0.1.11"
      end
      rel_path = "npm/node_modules/node-sass/node_modules/asn1/LICENSE"
      expected_path = File.join(SPEC_FIXTURES_DIR, rel_path)
      expect(asn1.version).to eq("0.1.11")
      expect(asn1.license).to be_nil
      expect(asn1.license_files).to eq([expected_path])
    end

    it "detects dependencies with no license info" do
      ansi = npm.dependencies.find { |d| d.name == "ansi" }
      expect(ansi.version).to eq("0.3.0")
      expect(ansi.license).to be_nil
      expect(ansi.license_files).to eq([])
    end

    describe "with default overrides enabled" do

      let(:overrides) { LicenseScout::Overrides.new() }

      before do
        allow(LicenseScout::NetFetcher).to receive(:new).and_call_original
        allow(LicenseScout::NetFetcher).to receive(:cache) do |url|
          LicenseScout::NetFetcher.new(url).cache_path
        end
      end

      it "fixes up dependencies with license metadata but no license files" do
        assert_plus_1_0_0 = npm.dependencies.find do |d|
          d.name == "assert-plus" && d.version = "1.0.0"
        end
        expect(assert_plus_1_0_0.license).to eq("MIT")

        rel_path = "npm/node_modules/assert-plus/README.md"
        expected_path = File.join(SPEC_FIXTURES_DIR, rel_path)
        expect(assert_plus_1_0_0.license_files).to eq([expected_path])
      end

      it "fixes up dependencies with license files but no metadata" do
        asn1 = npm.dependencies.find do |d|
          d.name == "asn1" && d.version == "0.1.11"
        end
        rel_path = "npm/node_modules/node-sass/node_modules/asn1/LICENSE"
        expected_path = File.join(SPEC_FIXTURES_DIR, rel_path)
        expect(asn1.version).to eq("0.1.11")
        expect(asn1.license).to eq("MIT")
        expect(asn1.license_files).to eq([expected_path])
      end

    end

    describe "when only license files are overridden." do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "js_npm", "assert-plus" do |version|
            {
              license_files: [ "package.json" ], # this is the only file we have in all versions
            }
          end
        end
      end

      it "only uses license file overrides and reports the original license" do
        assert_plus_1_0_0 = npm.dependencies.find do |d|
          d.name == "assert-plus" && d.version = "0.2.0"
        end
        expect(assert_plus_1_0_0.license).to eq("MIT")

        rel_path = "npm/node_modules/assert-plus/package.json"
        expected_path = File.join(SPEC_FIXTURES_DIR, rel_path)
        expect(assert_plus_1_0_0.license_files).to eq([ expected_path ])
      end

    end

    describe "when correct overrides are provided." do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "js_npm", "assert-plus" do |version|
            {
              license: "Apache",
              license_files: [ "package.json" ], # this is the only file we have in all versions
            }
          end
        end
      end

      it "uses the given overrides" do
        assert_plus_1_0_0 = npm.dependencies.find do |d|
          d.name == "assert-plus" && d.version = "1.0.0"
        end
        expect(assert_plus_1_0_0.license).to eq("Apache")

        rel_path = "npm/node_modules/assert-plus/package.json"
        expected_path = File.join(SPEC_FIXTURES_DIR, rel_path)
        expect(assert_plus_1_0_0.license_files).to eq([ expected_path ])
      end

    end

    describe "when overrides with missing license file paths are provided" do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "js_npm", "assert-plus" do |version|
            {
              license_files: [ "this-file-isnt-here" ],
            }
          end
        end
      end

      it "raises an error" do
        expect { npm.dependencies }.to raise_error(LicenseScout::Exceptions::InvalidOverride)
      end
    end
  end
end
