#
# Copyright:: Copyright 2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

RSpec.describe LicenseScout::DependencyManager::Cpanm do

  let(:directory) { "/some/random/directory" }
  let(:subject) { described_class.new(directory) }

  let(:meta_json_path) { File.join(directory, "META.json") }
  let(:meta_yaml_path) { File.join(directory, "META.yml") }

  let(:meta_json_exists) { true }
  let(:meta_yaml_exists) { false }

  describe ".new" do
    it "creates new instance of a dependency manager" do
      expect(subject.directory).to eql(directory)
    end
  end

  describe "#name" do
    it "equals 'perl_cpanm'" do
      expect(subject.name).to eql("perl_cpanm")
    end
  end

  describe "#type" do
    it "equals 'perl'" do
      expect(subject.type).to eql("perl")
    end
  end

  describe "#signature" do
    before do
      allow(File).to receive(:exist?).with(meta_json_path).and_return(meta_json_exists)
      allow(File).to receive(:exist?).with(meta_yaml_path).and_return(meta_yaml_exists)
    end

    context "when a META.yml exists" do
      let(:meta_yaml_exists) { true }
      let(:meta_json_exists) { false }

      it "equals 'META.yml file'" do
        expect(subject.signature).to eql("META.yml file")
      end
    end

    context "when a META.json exists" do
      it "equals 'META.json file'" do
        expect(subject.signature).to eql("META.json file")
      end
    end
  end

  describe "#install_command" do
    it "returns 'cpanm --installdeps .'" do
      expect(subject.install_command).to eql("cpanm --installdeps .")
    end
  end

  describe "#detected?" do
    before do
      allow(File).to receive(:exist?).with(meta_json_path).and_return(meta_json_exists)
      allow(File).to receive(:exist?).with(meta_yaml_path).and_return(meta_yaml_exists)
    end

    context "when META.json or META.yml exist" do
      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when META.json or META.yml are missing" do
      let(:meta_json_exists) { false }
      let(:meta_yaml_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end
  end

  describe "#dependencies", :no_windows do
    let(:tmpdir) { Dir.mktmpdir }
    let(:directory) { File.join(tmpdir, "App-Sqitch-0.973") }

    before do
      LicenseScout::Config.cpanm_root = File.join(SPEC_FIXTURES_DIR, "cpanm")
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    it "returns an array of Dependencies found in the directory" do
      dependencies = subject.dependencies
      expect(dependencies.length).to eq(84)

      # Has everything
      any_moose = dependencies.find { |d| d.name == "Any-Moose" }
      expect(any_moose.version).to eq("0.26")
      expect(any_moose.license.records.length).to eq(2)
      expect(any_moose.license.records.map(&:id)).to include("Artistic-1.0-Perl")
      expect(any_moose.license.records[0].source).to eql("LICENSE")
      expect(any_moose.license.records[1].source).to eql("META.json")

      # Check one missing license
      io_pager = dependencies.find { |d| d.name == "IO-Pager" }
      expect(io_pager.version).to eq("0.36")
      expect(io_pager.license.records.length).to eq(0)

      # Missing META.json
      class_load = dependencies.find { |d| d.name == "Class-Load" }
      expect(class_load.version).to eq("0.23")
      expect(class_load.license.records.map(&:id)).to include("Artistic-1.0-Perl")
      expect(any_moose.license.records[0].source).to eql("LICENSE")
      expect(any_moose.license.records[1].source).to eql("META.json")
    end
  end
end
