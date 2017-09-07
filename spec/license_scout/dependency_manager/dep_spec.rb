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

    it "detects the dependencies and their details correctly" do
      dependencies = dep.dependencies
      # Make sure we have the right count
      expect(dependencies.length).to eq(2)

      dep_a = dependencies.select { |d| d.name == "github.com_coreos_go-oidc" }
      dep_b = dependencies.select { |d| d.name == "gopkg.in_olivere_elastic.v5" }

      expect(dep_a.length).to be(1)
      expect(dep_a.first.version).to eq("a4973d9a4225417aecf5d450a9522f00c1f7130f")
      expect(dep_a.first.license).to eq(nil)
      expect(dep_a.first.license_files.first).to end_with("fixtures/deps_gopath/src/github.com/coreos/go-oidc/LICENSE")


      expect(dep_b.length).to be(1)
      expect(dep_b.first.version).to eq("v5.0.45")
      expect(dep_b.first.license).to eq(nil)
      expect(dep_b.first.license_files).to eq([])
    end

    describe "when given license overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new do
          override_license "go", "gopkg.in_olivere_elastic.v5" do |version|
            {
              license: "MIT",
            }
          end
        end
      end

      it "takes overrides into account" do
        dependencies = dep.dependencies
        expect(dependencies.length).to eq(2)

        dep_b = dependencies.find { |d| d.name == "gopkg.in_olivere_elastic.v5" }
        expect(dep_b.license).to eq("MIT")
      end

    end

    describe "when given license file overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new do
          override_license "go", "gopkg.in_olivere_elastic.v5" do |_version|
            {
              license_files: %w{README LICENSE},
            }
          end

        end
      end

      it "takes overrides into account" do
        dependencies = dep.dependencies
        expect(dependencies.length).to eq(2)

        dep_b = dependencies.find { |d| d.name == "gopkg.in_olivere_elastic.v5" }
        expect(dep_b.license_files[0]).to end_with("fixtures/deps_gopath/src/gopkg.in_olivere_elastic.v5/README")
        expect(dep_b.license_files[1]).to end_with("fixtures/deps_gopath/src/gopkg.in_olivere_elastic.v5/LICENSE")
      end

    end
  end
end
