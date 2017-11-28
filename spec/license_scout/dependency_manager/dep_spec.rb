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

require "license_scout/dependency_manager/dep"
require "license_scout/overrides"
require "license_scout/options"

RSpec.describe(LicenseScout::DependencyManager::Dep) do

  subject(:dep) do
    described_class.new(project_dir, LicenseScout::Options.new(
      overrides: overrides
    ))
  end

  let(:overrides) { LicenseScout::Overrides.new(exclude_default: true) }

  let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "dep") }

  it "has a name" do
    expect(dep.name).to eq("go_dep")
  end

  it "has a project directory" do
    expect(dep.project_dir).to eq(project_dir)
  end

  describe "when run in a non-dep project dir" do

    let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "no_dependency_manager") }

    it "does not detect the project" do
      expect(dep.detected?).to eq(false)
    end

  end

  describe "when run in a dep project dir" do
    before do
      ENV["GOPATH"] = File.join(SPEC_FIXTURES_DIR, "deps_gopath" )
    end

    it "does detects the project" do
      expect(dep.detected?).to eq(true)
    end

    it "detects the dependencies, finds license files, and scans license files for license type" do
      dependencies = dep.dependencies
      # Make sure we have the right count
      expect(dependencies.length).to eq(3)

      dep_a = dependencies.select { |d| d.name == "github.com_foo_bar" }
      dep_b = dependencies.select { |d| d.name == "gopkg.in_foo_baz" }

      expect(dep_a.length).to be(1)
      expect(dep_a.first.version).to eq("a4973d9a4225417aecf5d450a9522f00c1f7130f")
      expect(dep_a.first.license).to eq("Apache-2.0")
      expect(dep_a.first.license_files.first).to end_with("fixtures/deps_gopath/src/github.com/foo/bar/LICENSE")

      expect(dep_b.length).to be(1)
      expect(dep_b.first.version).to eq("v5.0.45")
      expect(dep_b.first.license).to eq(nil)
      expect(dep_b.first.license_files.first).to end_with("fixtures/deps_gopath/src/gopkg.in/foo/baz/LICENSE")
    end

    it "also checks vendor/ for license files" do
      dependencies = dep.dependencies
      expect(dependencies.length).to eq(3)

      dep_c = dependencies.select { |d| d.name == "github.com_f00_b4r" }
      puts dep_c
      expect(dep_c.length).to be(1)
      expect(dep_c.first.version).to eq("v0.0.1")
      expect(dep_c.first.license).to eq("MIT")
      expect(dep_c.first.license_files.first).to end_with("fixtures/dep/vendor/github.com/f00/b4r/LICENSE")
    end

    describe "when given license overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new do
          override_license "go", "gopkg.in/foo/baz" do |version|
            {
              license: "APACHE2",
            }
          end
        end
      end

      it "takes overrides into account" do
        dependencies = dep.dependencies
        expect(dependencies.length).to eq(3)

        dep_b = dependencies.find { |d| d.name == "gopkg.in_foo_baz" }
        expect(dep_b.license).to eq("APACHE2")
      end

    end

    describe "when given license file overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new do
          override_license "go", "gopkg.in/foo/baz" do |version|
            {
              license_files: %w{README LICENSE},
            }
          end

        end
      end

      it "takes overrides into account" do
        dependencies = dep.dependencies
        expect(dependencies.length).to eq(3)

        dep_b = dependencies.find { |d| d.name == "gopkg.in_foo_baz" }
        expect(dep_b.license_files[0]).to end_with("fixtures/deps_gopath/src/gopkg.in/foo/baz/README")
        expect(dep_b.license_files[1]).to end_with("fixtures/deps_gopath/src/gopkg.in/foo/baz/LICENSE")
      end

    end
  end
end
