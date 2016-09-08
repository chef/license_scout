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

require "license_scout/dependency_manager/manual"
require "license_scout/options"
require "license_scout/exceptions"

RSpec.describe(LicenseScout::DependencyManager::Manual) do
  subject(:manual) do
    described_class.new(project_dir, LicenseScout::Options.new(
      manual_licenses: manual_licenses
    ))
  end

  let(:project_dir) { Dir.mktmpdir }
  let(:manual_licenses) { nil }

  after do
    FileUtils.rm_rf(project_dir)
  end

  it "has a name" do
    expect(manual.name).to eq("manual")
  end

  describe "without manual license information" do
    it "does not report detected" do
      expect(manual.detected?).to eq(false)
    end
  end

  describe "given dependencies in the options" do
    let(:manual_licenses) do
      [
        {
          name: "logstash-websocket-plugin",
          version: "1.1.1",
          license: "MIT",
          license_files: ["LICENSE"],
        },
        {
          name: "elasticsearch",
          version: "2.1.3",
          license: "Apache-2.0",
          license_files: ["COPYING"],
        },
      ]
    end

    it "reports detected" do
      expect(manual.detected?).to eq(true)
    end

    it "lists the given dependencies" do
      deps = manual.dependencies
      expect(deps.length).to eq(2)
      expect(deps.first.name).to eq("logstash-websocket-plugin")
      expect(deps.first.license).to eq("MIT")
      expect(deps.first.version).to eq("1.1.1")
      expect(deps.last.name).to eq("elasticsearch")
      expect(deps.last.license_files).to eq(["COPYING"])
    end
  end

  describe "given dependencies in non-array form" do
    let(:manual_licenses) do
      {
        name: "logstash-websocket-plugin",
        version: "1.1.1",
        license: "MIT",
        license_files: ["LICENSE"],
      }
    end

    it "reports detected" do
      expect(manual.detected?).to eq(true)
    end

    it "raises error while listing dependencies" do
      expect { manual.dependencies }.to raise_error(LicenseScout::Exceptions::InvalidManualDependency, /should be an Array/)
    end
  end

  describe "given dependencies that contain unknown keys" do
    let(:manual_licenses) do
      [
        {
          name: "logstash-websocket-plugin",
          version: "1.1.1",
          license: "MIT",
          license_files: ["LICENSE"],
          unknown: "foo",
        },
      ]
    end

    it "reports detected" do
      expect(manual.detected?).to eq(true)
    end

    it "raises error while listing dependencies" do
      expect { manual.dependencies }.to raise_error(LicenseScout::Exceptions::InvalidManualDependency, /Key 'unknown' is not supported/)
    end
  end

end
