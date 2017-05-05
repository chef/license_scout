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

require "license_scout/dependency_manager/godep"
require "license_scout/overrides"
require "license_scout/options"

RSpec.describe(LicenseScout::DependencyManager::Godep) do

  subject(:godep) do
    described_class.new(project_dir, LicenseScout::Options.new(
      overrides: overrides
    ))
  end

  let(:overrides) { LicenseScout::Overrides.new(exclude_default: true) }

  let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "godep") }

  it "has a name" do
    expect(godep.name).to eq("go_godep")
  end

  it "has a project directory" do
    expect(godep.project_dir).to eq(project_dir)
  end

  describe "when run in a non-godep project dir" do

    let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "no_dependency_manager") }

    it "does not detect the project" do
      expect(godep.detected?).to eq(false)
    end

  end

  describe "when run in a godep project dir" do
    before do
      ENV["GOPATH"] = File.join(SPEC_FIXTURES_DIR, "godeps_gopath" )
    end

    it "does detects the project" do
      expect(godep.detected?).to eq(true)
    end

    it "detects the dependencies and their details correctly" do
      dependencies = godep.dependencies

      # Make sure we have the right count
      expect(dependencies.length).to eq(3)

      dep_a = dependencies.select { |d| d.name == "github.com_dep_a" }
      dep_b = dependencies.select { |d| d.name == "github.com_dep_b" }
      dep_c = dependencies.select { |d| d.name == "github.com_dep_c_subdir" }

      expect(dep_a.length).to be(1)
      expect(dep_a.first.version).to eq("rev0")
      expect(dep_a.first.license).to eq(nil)
      expect(dep_a.first.license_files.first).to end_with("fixtures/godeps_gopath/src/github.com/dep/a/LICENSE.txt")

      expect(dep_b.length).to be(1)
      expect(dep_b.first.version).to eq("v1.0.0")
      expect(dep_b.first.license).to eq(nil)
      expect(dep_b.first.license_files).to eq([])

      expect(dep_c.length).to be(1)
      expect(dep_c.first.version).to eq("rev2")
      expect(dep_c.first.license).to eq(nil)
      expect(dep_c.first.license_files.first).to end_with("fixtures/godeps_gopath/src/github.com/dep/c/subdir/LICENSE")
    end

    describe "when given license overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new do
          override_license "go", "github.com/dep/c/subdir" do |version|
            {
              license: "MIT",
            }
          end
        end
      end

      it "takes overrides into account" do
        dependencies = godep.dependencies
        expect(dependencies.length).to eq(3)

        dep_c = dependencies.find { |d| d.name == "github.com_dep_c_subdir" }
        expect(dep_c.license).to eq("MIT")
      end

    end

    describe "when given license file overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new do
          override_license "go", "github.com/dep/c/subdir" do |_version|
            {
              license_files: %w{README LICENSE},
            }
          end

        end
      end

      it "takes overrides into account" do
        dependencies = godep.dependencies
        expect(dependencies.length).to eq(3)

        dep_c = dependencies.find { |d| d.name == "github.com_dep_c_subdir" }
        expect(dep_c.license_files[0]).to end_with("fixtures/godeps_gopath/src/github.com/dep/c/subdir/README")
        expect(dep_c.license_files[1]).to end_with("fixtures/godeps_gopath/src/github.com/dep/c/subdir/LICENSE")
      end

    end
  end
end
