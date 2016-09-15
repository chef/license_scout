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

require "tmpdir"
require "fileutils"

require "license_scout/dependency_manager/cpanm"
require "license_scout/overrides"
require "license_scout/options"

RSpec.describe(LicenseScout::DependencyManager::Cpanm) do

  subject(:cpanm) do
    described_class.new(project_dir, LicenseScout::Options.new(
      overrides: overrides
    ))
  end

  let(:tmpdir) { Dir.mktmpdir }
  let(:project_dir) { File.join(tmpdir, "App-Example-1.0.0") }
  let(:overrides) { LicenseScout::Overrides.new(exclude_default: true) }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  it "has a name" do
    expect(cpanm.name).to eq("perl_cpanm")
  end

  describe "when provided a perl project with META.yml" do
    before do
      Dir.mkdir(project_dir)
      FileUtils.touch(File.join(project_dir, "META.yml"))
    end

    it "detects a perl project correctly" do
      expect(cpanm.detected?).to eq(true)
    end
  end

  describe "when provided a perl project with META.json" do
    before do
      Dir.mkdir(project_dir)
      FileUtils.touch(File.join(project_dir, "META.json"))
    end

    it "detects a perl project correctly" do
      expect(cpanm.detected?).to eq(true)
    end
  end

  describe "when provided a non-perl project" do
    before do
      Dir.mkdir(project_dir)
    end

    it "does not detect the project" do
      expect(cpanm.detected?).to eq(false)
    end
  end

  describe "when given a real cpan project" do

    let(:project_dir) { File.join(tmpdir, "App-Sqitch-0.973") }

    before do
      allow(cpanm).to receive(:cpanm_root).and_return(File.join(SPEC_FIXTURES_DIR, "cpanm"))
    end

    it "fetches the dependencies" do
      deps = cpanm.dependencies
      expect(deps.length).to eq(85)

      # Has everything
      any_moose = deps.select { |d| d.name == "Any-Moose" }
      expect(any_moose.length).to eq(1)
      expect(any_moose.first.license).to eq("Perl-5")
      expect(any_moose.first.version).to eq("0.26")
      expect(any_moose.first.license_files.length).to eq(1)
      expect(any_moose.first.license_files.first).to end_with("latest-build/Any-Moose-0.26/LICENSE")

      # Check one missing #license
      io_pager = deps.select { |d| d.name == "IO-Pager" }
      expect(io_pager.length).to eq(1)
      expect(io_pager.first.license).to eq(nil)
      expect(io_pager.first.version).to eq("0.36")
      expect(io_pager.first.license_files).to be_empty

      # Missing META.json
      class_load = deps.select { |d| d.name == "Class-Load" }
      expect(class_load.length).to eq(1)
      expect(class_load.first.license).to eq("Perl-5")
      expect(class_load.first.version).to eq("0.23")
      expect(class_load.first.license_files.length).to eq(1)
      expect(class_load.first.license_files.first).to end_with("latest-build/Class-Load-0.23/LICENSE")
    end
    # Make sure it happens when META.yml or META.json does not exist.
    describe "with overrides" do

      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "perl_cpanm", "Any-Moose" do |version|
            {
              license: "MIT",
              license_files: ["README"] # any file in Capture-Tiny there
            }
          end
        end
      end

      it "detects the licenses of the transitive dependencies correctly" do
        expect(cpanm.dependencies.size).to eq(85)

        any_moose = cpanm.dependencies.select { |d| d.name == "Any-Moose" }
        expect(any_moose.length).to eq(1)
        expect(any_moose.first.license).to eq("MIT")
        expect(any_moose.first.version).to eq("0.26")
        expect(any_moose.first.license_files.length).to eq(1)
        expect(any_moose.first.license_files.first).to end_with("latest-build/Any-Moose-0.26/README")
      end
    end

  end
end
