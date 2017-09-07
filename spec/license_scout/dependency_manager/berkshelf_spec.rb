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

require "license_scout/dependency_manager/berkshelf"
require "license_scout/options"

RSpec.describe(LicenseScout::DependencyManager::Berkshelf) do

  subject(:berkshelf) do
    described_class.new(project_dir, LicenseScout::Options.new(
      overrides: overrides
    ))
  end

  let(:tmpdir) { Dir.mktmpdir }

  let(:overrides) { LicenseScout::Overrides.new(exclude_default: true) }
  let(:project_dir) { File.join(tmpdir, "berkshelf_project") }

  before do
    ENV["BERKSHELF_PATH"] = File.join(SPEC_FIXTURES_DIR, "berkshelf_cache_dir" )
  end

  after do
    ENV.delete("BERKSHELF_PATH")
  end

  it "has a name" do
    expect(berkshelf.name).to eq("chef_berkshelf")
  end

  it "does not detect berkshelf when both berksfile and lockfile are missing" do
    expect(berkshelf.detected?).to eq(false)
  end

  describe "when only Berksfile exists" do

    before do
      Dir.mkdir(project_dir)
      FileUtils.touch(File.join(project_dir, "Berksfile"))
    end

    it "does not detect" do
      expect(berkshelf.detected?).to eq(false)
    end

  end

  describe "when only Berksfile.lock exists" do

    before do
      Dir.mkdir(project_dir)
      FileUtils.touch(File.join(project_dir, "Berksfile.lock"))
    end

    it "does not detect" do
      expect(berkshelf.detected?).to eq(false)
    end

  end

  describe "with a full berkshelf project" do
    let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "berkshelf") }

    it "detects berkshelf correctly" do
      expect(berkshelf.detected?).to eq(true)
    end

    it "detects the dependencies and their details correctly" do
      dependencies = berkshelf.dependencies

      # Make sure we have the right count
      expect(dependencies.length).to eq(20)

      # Spot check a few of the dependencies

      omnibus = dependencies.select { |d| d.name == "omnibus" }
      git = dependencies.select { |d| d.name == "git" }
      windows = dependencies.select { |d| d.name == "windows" }

      expect(omnibus.length).to be(1)
      expect(omnibus.first.version).to eq("4.2.4")
      expect(omnibus.first.license).to eq("Apache 2.0")
      expect(omnibus.first.license_files.length).to be(1)
      expect(omnibus.first.license_files.first).to end_with("fixtures/berkshelf_cache_dir/cookbooks/omnibus-4.2.4/LICENSE")

      expect(git.length).to be(1)
      expect(git.first.version).to eq("4.6.0")
      expect(git.first.license).to eq("Apache 2.0")
      expect(git.first.license_files).to be_empty

      expect(windows.length).to be(1)
      expect(windows.first.version).to eq("1.44.3")
      expect(windows.first.license).to eq("Apache 2.0")
      expect(windows.first.license_files).to be_empty

    end

    describe "when berkshelf is not available" do
      before do
        expect(berkshelf).to receive(:require).with("berkshelf") do
          raise LoadError
        end
      end

      it "raises an error" do
        expect { berkshelf.dependencies }.to raise_error(LicenseScout::Exceptions::Error, /berkshelf gem is not available/)
      end
    end

    describe "when given license overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "chef_berkshelf", "windows" do |version|
            {
              license: "MIT",
            }
          end
        end
      end

      it "takes overrides into account" do
        dependencies = berkshelf.dependencies
        expect(dependencies.length).to eq(20)

        windows = dependencies.select { |d| d.name == "windows" }

        expect(windows.length).to be(1)
        expect(windows.first.version).to eq("1.44.3")
        expect(windows.first.license).to eq("MIT")
        expect(windows.first.license_files).to be_empty
      end

    end

    describe "when given license file overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "chef_berkshelf", "git" do |version|
            {
              license_files: ["README.md", "CHANGELOG.md"],
            }
          end

        end
      end

      it "takes overrides into account" do
        dependencies = berkshelf.dependencies
        expect(dependencies.length).to eq(20)

        git = dependencies.select { |d| d.name == "git" }

        expect(git.length).to be(1)
        expect(git.first.version).to eq("4.6.0")
        expect(git.first.license).to eq("Apache 2.0")
        expect(git.first.license_files.length).to eq(2)
        expect(git.first.license_files.first).to end_with("fixtures/berkshelf_cache_dir/cookbooks/git-4.6.0/README.md")
        expect(git.first.license_files[1]).to end_with("fixtures/berkshelf_cache_dir/cookbooks/git-4.6.0/CHANGELOG.md")
      end

    end

    describe "when given both license and license file overrides" do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "chef_berkshelf", "omnibus" do |version|
            {
              license: "MIT",
              license_files: ["TESTING.md"],
            }
          end

        end
      end

      it "takes overrides into account" do
        dependencies = berkshelf.dependencies
        expect(dependencies.length).to eq(20)

        omnibus = dependencies.select { |d| d.name == "omnibus" }

        expect(omnibus.length).to be(1)
        expect(omnibus.first.version).to eq("4.2.4")
        expect(omnibus.first.license).to eq("MIT")
        expect(omnibus.first.license_files.length).to be(1)
        expect(omnibus.first.license_files.first).to end_with("fixtures/berkshelf_cache_dir/cookbooks/omnibus-4.2.4/TESTING.md")
      end

    end

  end

end
