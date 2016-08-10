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

require "license_scout/collector"
require "license_scout/dependency_manager/base"

module LicenseScout
  module DependencyManager

    class TestDepManager < Base

      def name
        "test_dep_manager"
      end

      def detected?
        true
      end

      def dependencies
        license = File.join(SPEC_FIXTURES_DIR, "test_licenses/LICENSE")
        copying = File.join(SPEC_FIXTURES_DIR, "test_licenses/COPYING")
        [
          Dependency.new("example1", "1.0.0", "MIT", [license, copying]),
          Dependency.new("example2", "1.2.3", "Apache-2", [copying]),
        ]
      end
    end

    class MissingLicenseDepManager < Base

      def name
        "missing_license_dep_manager"
      end

      def detected?
        true
      end

      def dependencies
        license = File.join(SPEC_FIXTURES_DIR, "test_licenses/LICENSE")
        copying = File.join(SPEC_FIXTURES_DIR, "test_licenses/COPYING")
        [
          { name: "example1", version: "1.0.0", license: "MIT", files: [license, copying] },
          { name: "example2", version: "1.2.3", license: nil, files: [] },
        ].map do |dependency|
          license = overrides.license_for(name, dependency[:name], dependency[:version]) || dependency[:license]
          license_files = []

          override_files = overrides.license_files_for(name, dependency[:name], dependency[:version])
          if !override_files.empty?
            license_files = override_files.map { |f| File.join(SPEC_FIXTURES_DIR, "test_licenses/#{f}") }
          else
            license_files = dependency[:files]
          end

          Dependency.new(dependency[:name], dependency[:version], license, license_files)
        end
      end
    end

    class UnsupportedProjectTypeDepManager < Base

      def name
        "unsupported_dep_manager"
      end

      def detected?
        false
      end

      def dependencies
        []
      end
    end

  end
end

require "tmpdir"
require "fileutils"

RSpec.describe(LicenseScout::Collector) do

  let(:tmpdir) { Dir.mktmpdir }

  let(:project_dir) { File.join(tmpdir, "project_dir") }
  let(:output_dir) { File.join(tmpdir, "output_dir") }
  let(:project_name) { "example-project" }
  let(:overrides) { LicenseScout::Overrides.new }

  subject(:collector) { described_class.new(project_name, project_dir, output_dir, overrides, {}) }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  it "has a project name" do
    expect(collector.project_name).to eq(project_name)
  end

  it "has a project directory where it looks for dependencies" do
    expect(collector.project_dir).to eq(project_dir)
  end

  it "has an output directory where it copies licenses" do
    expect(collector.output_dir).to eq(output_dir)
  end

  context "when the project directory doesn't exist" do

    let(:project_dir) { File.join(tmpdir, "nope") }

    it "fails" do
      expect { collector.run }.to raise_error(LicenseScout::Exceptions::ProjectDirectoryMissing)
    end
  end

  describe "when run on a supported project type" do

    before do
      allow(LicenseScout::DependencyManager).to receive(:implementations).
        and_return([LicenseScout::DependencyManager::TestDepManager])
      Dir.mkdir(project_dir)
    end

    let(:expected_license_file_names) do
      %w{
        test_dep_manager-example1-1.0.0-LICENSE
        test_dep_manager-example1-1.0.0-COPYING
        test_dep_manager-example2-1.2.3-COPYING
      }
    end

    let(:expected_license_file_paths) do
      expected_license_file_names.map { |f| File.join(output_dir, f) }
    end

    let(:expected_machine_readable_licenses_file) do
      File.join(output_dir, "example-project-dependency-licenses.json")
    end

    let(:expected_machine_readable_licenses_content) do
      {
        "license_manifest_version" => 1,
        "project_name" => "example-project",
        "dependency_managers" => {
          "test_dep_manager" => [
            {
              "name" => "example1",
              "version" => "1.0.0",
              "license" => "MIT",
              "license_files" => [
                "test_dep_manager-example1-1.0.0-LICENSE",
                "test_dep_manager-example1-1.0.0-COPYING",
               ],
            },
            {
              "name" => "example2",
              "version" => "1.2.3",
              "license" => "Apache-2",
              "license_files" => [
                "test_dep_manager-example2-1.2.3-COPYING",
               ],
            },

          ],
        },
      }
    end

    it "detects the dependency manager(s) the project uses" do
      expect(collector.dependency_managers.size).to eq(1)
      expect(collector.dependency_managers.first).to be_a(LicenseScout::DependencyManager::TestDepManager)
    end

    it "collects license files from dependencies and copies them to an output dir" do
      collector.run
      expected_license_file_paths.each do |path|
        expect(File).to exist(path)
      end
    end

    it "emits a JSON file with a list of dependencies and relative paths to the license files" do
      collector.run
      expect(File).to exist(expected_machine_readable_licenses_file)
      content = FFI_Yajl::Parser.parse(File.read(expected_machine_readable_licenses_file))
      expect(content).to eq(expected_machine_readable_licenses_content)
    end

    it "does not report any missing license information" do
      collector.run
      expect(collector.issue_report).to be_empty
    end

    context "when a dependency's license cannot be detected" do

      before do
        allow(LicenseScout::DependencyManager).to receive(:implementations).
          and_return([LicenseScout::DependencyManager::MissingLicenseDepManager])
      end

      context "and the dependency's license is not manually specified" do

        let(:expected_machine_readable_licenses_content) do
          {
            "license_manifest_version" => 1,
            "project_name" => "example-project",
            "dependency_managers" => {
              "missing_license_dep_manager" => [
                {
                  "name" => "example1",
                  "version" => "1.0.0",
                  "license" => "MIT",
                  "license_files" => [
                    "missing_license_dep_manager-example1-1.0.0-LICENSE",
                    "missing_license_dep_manager-example1-1.0.0-COPYING",
                   ],
                },
                {
                  "name" => "example2",
                  "version" => "1.2.3",
                  "license" => nil,
                  "license_files" => [
                   ],
                },

              ],
            },
          }
        end

        # This ensures that re-running a build with invalid dependencies still
        # fails even if the softwares are restored from git cache.
        it "embeds information about invalid dependencies in the license manifest" do
          collector.run
          expect(File).to exist(expected_machine_readable_licenses_file)
          content = FFI_Yajl::Parser.parse(File.read(expected_machine_readable_licenses_file))
          expect(content).to eq(expected_machine_readable_licenses_content)
        end

        it "reports missing licenses and license files" do
          collector.run
          report = collector.issue_report
          expect(report).to include("Dependency 'example2' version '1.2.3' under 'missing_license_dep_manager' is missing license information.")
          expect(report).to include("Dependency 'example2' version '1.2.3' under 'missing_license_dep_manager' is missing license files information.")
        end
      end

      context "and the dependency's license is manually specified" do
        let(:overrides) do
          LicenseScout::Overrides.new() do
            override_license "missing_license_dep_manager", "example1" do |version|
              {
                license: "BSD",
                license_files: [ "BSD-LICENSE" ],
              }
            end
          end
        end

        let(:expected_license_file_names) do
          %w{
            missing_license_dep_manager-example1-1.0.0-BSD-LICENSE
          }
        end

        let(:expected_machine_readable_licenses_content) do
          {
            "license_manifest_version" => 1,
            "project_name" => "example-project",
            "dependency_managers" => {
              "missing_license_dep_manager" => [
                {
                  "name" => "example1",
                  "version" => "1.0.0",
                  "license" => "BSD",
                  "license_files" => [
                    "missing_license_dep_manager-example1-1.0.0-BSD-LICENSE",
                   ],
                },
                {
                  "name" => "example2",
                  "version" => "1.2.3",
                  "license" => nil,
                  "license_files" => [
                   ],
                },

              ],
            },
          }
        end

        it "copies the license info specified in the override" do
          collector.run
          expected_license_file_paths.each do |path|
            expect(File).to exist(path)
          end
        end

        it "includes the info specified in the override file, in the license manifest file" do
          collector.run
          expect(File).to exist(expected_machine_readable_licenses_file)
          content = FFI_Yajl::Parser.parse(File.read(expected_machine_readable_licenses_file))
          expect(content).to eq(expected_machine_readable_licenses_content)
        end
      end

    end
  end

  describe "when run on an unsupported project type" do

    before do
      allow(LicenseScout::DependencyManager).to receive(:implementations).
        and_return([LicenseScout::DependencyManager::UnsupportedProjectTypeDepManager])
      Dir.mkdir(project_dir)
    end

    it "fails when it cannot find a supported dependency manager" do
      expect { collector.run }.to raise_error(LicenseScout::Exceptions::UnsupportedProjectType)
    end
  end

end

## STUFF OMNIBUS DOES:

# it collects intermediate transitive deps and merges them
# it includes a LICENSE.json version of the LICENSE file
# it reads the per-project license manifest JSON and reports errors when license is nil/null or license files are empty
# it invalidates the git cache for any software that uses license scout when the license overrides file/project/repo is updated
