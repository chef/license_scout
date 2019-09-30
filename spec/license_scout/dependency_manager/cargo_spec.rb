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

RSpec.describe LicenseScout::DependencyManager::Cargo do

  let(:subject) { described_class.new(directory) }
  let(:directory) { "/some/random/directory" }

  let(:cargo_file_path) { File.join(directory, "Cargo.toml") }
  let(:cargo_lockfile_path) { File.join(directory, "Cargo.lock") }

  describe ".new" do
    it "creates new instance of a dependency manager" do
      expect(subject.directory).to eql(directory)
    end
  end

  describe "#name" do
    it "equals 'rust_cargo'" do
      expect(subject.name).to eql("rust_cargo")
    end
  end

  describe "#type" do
    it "equals 'rust'" do
      expect(subject.type).to eql("rust")
    end
  end

  describe "#signature" do
    it "equals 'Cargo and Cargo.lock files'" do
      expect(subject.signature).to eql("Cargo and Cargo.lock files")
    end
  end

  describe "#install_command" do
    it "returns 'cargo build'" do
      expect(subject.install_command).to eql("cargo build")
    end
  end

  describe "#detected?" do
    let(:cargo_file_exists) { true }
    let(:cargo_file_lock_exists) { true }

    before do
      expect(File).to receive(:exist?).with(cargo_file_path).and_return(cargo_file_exists)
      expect(File).to receive(:exist?).with(cargo_lockfile_path).and_return(cargo_file_lock_exists)
    end

    context "when Cargo and Cargo.lock exist" do
      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when either Cargo or Cargo.lock is missing" do
      let(:cargo_file_exists) { true }
      let(:cargo_file_lock_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end
  end

  describe "#dependencies" do
    context "cargo project" do
      let(:directory) { File.join(SPEC_FIXTURES_DIR, "cargo") }
      let(:expected_count) { 35 }

      it "returns an array of Dependencies found in the directory" , :no_windows do
        dependencies = subject.dependencies

        # Make sure we have the right count
        expect(dependencies.length).to eq(expected_count)
      end
    end
  end
end
