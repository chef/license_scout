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

require "license_scout/dependency_manager/bundler"
require "license_scout/overrides"

RSpec.describe(LicenseScout::DependencyManager::Bundler) do
  subject(:bundler) { described_class.new(project_dir, overrides, {}) }

  let(:tmpdir) { Dir.mktmpdir }

  let(:overrides) { LicenseScout::Overrides.new }
  let(:project_dir) { File.join(tmpdir, "bundler_project") }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  it "has a name" do
    expect(bundler.name).to eq("ruby_bundler")
  end

  it "has a project directory" do
    expect(bundler.project_dir).to eq(project_dir)
  end

  describe "when provided a bundler project" do
    before do
      Dir.mkdir(project_dir)
      FileUtils.touch(File.join(project_dir, "Gemfile"))
      FileUtils.touch(File.join(project_dir, "Gemfile.lock"))
    end

    it "detects a bundler project correctly" do
      expect(bundler.detected?).to eq(true)
    end
  end

  describe "when provided a non-bundler project" do
    before do
      Dir.mkdir(project_dir)
    end

    it "does not detect the project" do
      expect(bundler.detected?).to eq(false)
    end
  end

  describe "when provided a bundler project without lock file" do
    before do
      Dir.mkdir(project_dir)
      FileUtils.touch(File.join(project_dir, "Gemfile"))
    end

    it "detects the project as a bundler project" do
      expect(bundler.detected?).to eq(true)
    end

    it "raises an error when asking for dependencies" do
      expect { bundler.dependencies }.to raise_error(LicenseScout::Exceptions::DependencyManagerNotRun)
    end
  end

  describe "when provided a real bundler project" do
    let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "bundler") }

    it "detects the licenses of the transitive dependencies correctly" do
      dependencies = bundler.dependencies
      expect(dependencies.length).to eq(10)

      # We check the bundler intentionally because we are munging with its
      # license information in the code.
      bundler_info = dependencies.find { |d| d.name == "bundler" }
      expect(bundler_info.license).to eq("MIT")
      expect(bundler_info.license_files.length).to eq(1)
      expect(bundler_info.license_files.first).to end_with("/LICENSE.md")

      # We check mixlib-install an example out of 10 dependencies.
      mixlib_install_info = dependencies.find { |d| d.name == "mixlib-install" }
      expect(mixlib_install_info.version).to eq("1.1.0")
      expect(mixlib_install_info.license).to eq("Apache-2.0")
      expect(mixlib_install_info.license_files.length).to eq(1)
      expect(mixlib_install_info.license_files.first).to end_with("spec/fixtures/bundler/vendor/bundle/ruby/2.1.0/gems/mixlib-install-1.1.0/LICENSE")
    end

    describe "when only license files are overridden." do
      let(:overrides) {
        LicenseScout::Overrides.new() do
          override_license "ruby_bundler", "mixlib-install" do |version|
            {
              license_files: [ "CHANGELOG.md" ], # pick any file from mixlib-install
            }
          end
        end
      }

      it "only uses license file overrides and reports the original license" do
        dependencies = bundler.dependencies
        expect(dependencies.length).to eq(10)

        mixlib_install_info = dependencies.find { |d| d.name == "mixlib-install" }
        expect(mixlib_install_info.version).to eq("1.1.0")
        expect(mixlib_install_info.license).to eq("Apache-2.0")
        expect(mixlib_install_info.license_files.length).to eq(1)
        expect(mixlib_install_info.license_files.first).to end_with("spec/fixtures/bundler/vendor/bundle/ruby/2.1.0/gems/mixlib-install-1.1.0/CHANGELOG.md")
      end
    end

    describe "when correct overrides are provided." do
      let(:overrides) {
        LicenseScout::Overrides.new() do
          override_license "ruby_bundler", "mixlib-install" do |version|
            {
              license: "Apache",
              license_files: [ "README.md" ],
            }
          end
        end
      }

      it "uses the given overrides" do
        dependencies = bundler.dependencies
        expect(dependencies.length).to eq(10)

        mixlib_install_info = dependencies.find { |d| d.name == "mixlib-install" }
        expect(mixlib_install_info.version).to eq("1.1.0")
        expect(mixlib_install_info.license).to eq("Apache")
        expect(mixlib_install_info.license_files.length).to eq(1)
        expect(mixlib_install_info.license_files.first).to end_with("spec/fixtures/bundler/vendor/bundle/ruby/2.1.0/gems/mixlib-install-1.1.0/README.md")
      end
    end

    describe "when overrides with missing license file paths are provided" do
      let(:overrides) {
        LicenseScout::Overrides.new() do
          override_license "ruby_bundler", "mixlib-install" do |version|
            {
              license: "Apache",
              license_files: [ "NOPE-LICENSE" ],
            }
          end
        end
      }

      it "raises an error" do
        expect { bundler.dependencies }.to raise_error(LicenseScout::Exceptions::InvalidOverride)
      end
    end
  end
end
