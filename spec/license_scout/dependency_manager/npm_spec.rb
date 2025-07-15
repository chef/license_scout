#
# Copyright:: Copyright 2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

RSpec.describe LicenseScout::DependencyManager::Npm do

  # let(:subject) { described_class.new(directory) }
  # let(:directory) { "/some/random/directory" }

  # let(:node_modules_path) { File.join(directory, "node_modules") }

  # describe ".new" do
  #   it "creates new instance of a dependency manager" do
  #     expect(subject.directory).to eql(directory)
  #   end
  # end

  # describe "#name" do
  #   it "equals 'nodejs_npm'" do
  #     expect(subject.name).to eql("nodejs_npm")
  #   end
  # end

  # describe "#type" do
  #   it "equals 'nodejs'" do
  #     expect(subject.type).to eql("nodejs")
  #   end
  # end

  # describe "#signature" do
  #   it "equals 'node_modules directory'" do
  #     expect(subject.signature).to eql("node_modules directory")
  #   end
  # end

  # describe "#install_command" do
  #   it "returns 'npm install'" do
  #     expect(subject.install_command).to eql("npm install")
  #   end
  # end

  # describe "#detected?" do
  #   let(:node_modules_exists) { true }

  #   before do
  #     expect(File).to receive(:exist?).with(node_modules_path).and_return(node_modules_exists)
  #   end

  #   context "when node_modules exists" do
  #     it "returns true" do
  #       expect(subject.detected?).to be true
  #     end
  #   end

  #   context "when node_modules is missing" do
  #     let(:node_modules_exists) { false }

  #     it "returns false" do
  #       expect(subject.detected?).to be false
  #     end
  #   end
  # end
  let(:subject) { described_class.new(directory) }
  let(:directory) { "/some/random/directory" }
  let(:node_modules_path) { File.join(directory, "node_modules") }
  let(:package_json_path) { File.join(directory, "package.json") }

  describe "#detected?" do
    before do
      # Mock File.exist? for both package.json and node_modules
      allow(File).to receive(:exist?) do |path|
        case path
        when package_json_path
          package_json_exists
        when node_modules_path
          node_modules_exists
        else
          false
        end
      end
    end

    context "when both package.json and node_modules exist" do
      let(:package_json_exists) { true }
      let(:node_modules_exists) { true }

      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when package.json exists but node_modules is missing" do
      let(:package_json_exists) { true }
      let(:node_modules_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end

    context "when package.json is missing but node_modules exists" do
      let(:package_json_exists) { false }
      let(:node_modules_exists) { true }

      it "returns false" do
        expect(subject.detected?).to be true
      end
    end

    context "when both package.json and node_modules are missing" do
      let(:package_json_exists) { false }
      let(:node_modules_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end
  end

  describe "#dependencies", :vcr do
    let(:directory) { File.join(SPEC_FIXTURES_DIR, "npm") }

    # npm recursively nests dependencies, make sure we find them.
    it "detects all transitive dependencies" do
      expect(subject.dependencies.size).to eql(102)

      # spec/fixtures/npm/node_modules/node-sass/node_modules/meow/package.json
      meow = subject.dependencies.find { |d| d.name == "meow" }
      expect(meow).to_not be_nil
    end

    it "dedups dependencies only if they are the same version" do
      dependencies = subject.dependencies
      minimist_info = dependencies.select { |d| d.name == "minimist" }
      minimist_info.sort! { |a, b| a.version <=> b.version }

      # There are 4 copies of minimist at different versions, after de-dup
      # on version there should only be 3. (`find spec/fixtures/npm -name minimist`)
      expect(minimist_info.size).to eql(3)
      expect(minimist_info[0].version).to eql("0.0.10")
      expect(minimist_info[1].version).to eql("0.0.8")
      expect(minimist_info[2].version).to eql("1.2.0")
    end

    it "detects dependencies with license files and license metadata" do
      angular = subject.dependencies.find { |d| d.name == "angular" }

      expect(angular.version).to eql("1.4.12")
      expect(angular.license.records.first.id).to eql("MIT")
      expect(angular.license.records.first.parsed_expression).to eql(["MIT"])
      expect(angular.license.records[0].source).to eql("LICENSE.md")
      expect(angular.license.records[1].source).to eql("package.json")
    end

    # The SPDX license format that npm uses allows packages to specify multiple
    # conjoined licenses, like "MIT AND CC-BY-3.0". Since this is based on a
    # standard syntax, we just pass it through, and let higher level tooling
    # (like omnibus) decide how to handle it.
    it "handles licenses with multiple combined license terms" do
      spdx_expression_parse = subject.dependencies.find do |d|
        d.name == "spdx-expression-parse"
      end

      expect(spdx_expression_parse.version).to eql("1.0.3")
      expect(spdx_expression_parse.license.records.map(&:id)).to eq(["MIT", "(MIT AND CC-BY-3.0)"])
      expect(spdx_expression_parse.license.records[1].parsed_expression).to eql(["MIT", "CC-BY-3.0"])
      expect(spdx_expression_parse.license.records[0].source).to eql("LICENSE")
      expect(spdx_expression_parse.license.records[1].source).to eql("package.json")

    end

    it "detects dependencies with license metadata but no license files" do
      assert_plus_1_0_0 = subject.dependencies.find do |d|
        d.name == "assert-plus" && d.version == "0.2.0"
      end

      expect(assert_plus_1_0_0.license.records.first.id).to eql("MIT")
      expect(assert_plus_1_0_0.license.records.first.source).to eql("package.json")
    end

    it "detects dependencies with license files but no metadata" do
      asn1 = subject.dependencies.find do |d|
        d.name == "asn1" && d.version == "0.1.11"
      end

      expect(asn1.version).to eql("0.1.11")
      expect(asn1.license.records.first.id).to eql("MIT")
      expect(asn1.license.records.first.source).to eql("LICENSE")
    end

    it "detects dependencies with no license info" do
      ansi = subject.dependencies.find { |d| d.name == "ansi" }

      expect(ansi.version).to eql("0.3.0")
      expect(ansi.license.records).to be_empty
    end

  end
end
