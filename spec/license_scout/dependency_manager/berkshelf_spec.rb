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

RSpec.describe LicenseScout::DependencyManager::Berkshelf do

  let(:subject) { described_class.new(directory) }
  let(:directory) { "/some/random/directory" }

  let(:berksfile_path) { File.join(directory, "Berksfile") }
  let(:berksfile_lock_path) { File.join(directory, "Berksfile.lock") }

  describe ".new" do
    it "creates new instance of a dependency manager" do
      expect(subject.directory).to eql(directory)
    end
  end

  describe "#name" do
    it "equals 'chef_berkshelf'" do
      expect(subject.name).to eql("chef_berkshelf")
    end
  end

  describe "#type" do
    it "equals 'chef_cookbook'" do
      expect(subject.type).to eql("chef_cookbook")
    end
  end

  describe "#signature" do
    it "equals 'Berksfile and Berksfile.lock files'" do
      expect(subject.signature).to eql("Berksfile and Berksfile.lock files")
    end
  end

  describe "#detected?" do
    let(:berksfile_exists) { true }
    let(:berksfile_lock_exists) { true }

    before do
      expect(File).to receive(:exist?).with(berksfile_path).and_return(berksfile_exists)
      expect(File).to receive(:exist?).with(berksfile_lock_path).and_return(berksfile_lock_exists)
    end

    context "when Berksfile and Berksfile.lock exist" do
      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when either Berksfile or Berksfile.lock is missing" do
      let(:berksfile_exists) { true }
      let(:berksfile_lock_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end
  end

  describe "#install_command" do
    it "returns 'berks install'" do
      expect(subject.install_command).to eql("berks install")
    end
  end

  describe "#dependencies" do
    before do
      ENV["BERKSHELF_PATH"] = File.join(SPEC_FIXTURES_DIR, "berkshelf_cache_dir" )
    end

    after do
      ENV.delete("BERKSHELF_PATH")
    end

    let(:directory) { File.join(SPEC_FIXTURES_DIR, "berkshelf") }

    context "when the 'berkshelf' gem is unavailable" do
      before do
        expect(subject).to receive(:require).with("berkshelf") do
          raise LoadError
        end
      end

      it "raises an error" do
        expect { subject.dependencies }.to raise_error(LicenseScout::Exceptions::Error, /berkshelf gem is not available/)
      end
    end

    it "returns an array of Dependencies found in the directory" do
      dependencies = subject.dependencies

      # Make sure we have the right count
      expect(dependencies.length).to eq(20)

      # Spot check a few of the dependencies
      omnibus = dependencies.select { |d| d.name == "omnibus" }
      git = dependencies.select { |d| d.name == "git" }
      windows = dependencies.select { |d| d.name == "windows" }

      expect(omnibus.length).to be(1)
      expect(omnibus.first.version).to eq("4.2.4")
      expect(omnibus.first.license.records.length).to be(1)
      expect(omnibus.first.license.records.first.id).to eq("Apache-2.0")
      expect(omnibus.first.license.records.first.source).to eql("LICENSE")

      expect(git.length).to be(1)
      expect(git.first.version).to eq("4.6.0")
      expect(git.first.license.records.length).to eql(0)

      expect(windows.length).to be(1)
      expect(windows.first.version).to eq("1.44.3")
      expect(git.first.license.records.length).to eql(0)
    end
  end
end
