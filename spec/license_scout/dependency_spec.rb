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

RSpec.describe LicenseScout::Dependency do

  let(:name) { "artifactory" }
  let(:version) { "2.3.3" }
  let(:type) { "ruby" }
  let(:path) { File.join(SPEC_FIXTURES_DIR, "bundler_gems_dir", "gems", "#{name}-#{version}") }

  let(:license) { LicenseScout::License.new }

  let(:subject) { described_class.new(name, version, path, type) }

  describe ".new" do
    context "when path is nil" do
      let(:path) { nil }

      it "returns an empty license" do
        expect(LicenseScout::License).to receive(:new).and_return(license)
        expect(subject.name).to eql(name)
        expect(subject.version).to eql(version)
        expect(subject.type).to eql(type)
        expect(subject.path).to eql(path)
        expect(subject.license).to eql(license)
      end
    end

    context "when path is an HTTP url" do
      let(:name) { "bundler" }
      let(:version) { "1.16.0" }
      let(:path) { "https://github.com/bundler/bundler" }

      it "returns a complete license" do
        expect(LicenseScout::License).to receive(:new).with(path).and_return(license)
        expect(subject.name).to eql(name)
        expect(subject.version).to eql(version)
        expect(subject.type).to eql(type)
        expect(subject.path).to eql(path)
        expect(subject.license).to eql(license)
      end
    end

    context "when path is a valid directory path" do
      it "returns a complete license" do
        expect(LicenseScout::License).to receive(:new).with(path).and_return(license)
        expect(subject.name).to eql(name)
        expect(subject.version).to eql(version)
        expect(subject.type).to eql(type)
        expect(subject.path).to eql(path)
        expect(subject.license).to eql(license)
      end
    end

    context "when path is an invalid directory path" do
      let(:path) { "invalid-path" }

      it "raises an error" do
        expect { subject }.to raise_error(LicenseScout::Exceptions::MissingSourceDirectory, /Could not find the source for '#{name}'/)
      end
    end

    context "when there is a fallback license specified for the dependency", :vcr do
      let(:license_file) { "https://raw.githubusercontent.com/bundler/bundler/master/LICENSE.md" }

      before do
        LicenseScout::Config.fallbacks.ruby = [{
          "name" => name,
          "license_id" => "MIT",
          "license_file" => license_file,
        }]
      end

      it "includes that license" do
        expect(LicenseScout::License).to receive(:new).with(path).and_return(license)
        expect(license).to receive(:add_license).with("MIT", "license_scout fallback", license_file, force: true)
        expect(subject.name).to eql(name)
        expect(subject.version).to eql(version)
        expect(subject.type).to eql(type)
        expect(subject.path).to eql(path)
        expect(subject.license).to eql(license)
      end
    end
  end

  describe "#uid" do
    it "returns the identifying string" do
      expect(subject.uid).to eql("#{name} (#{version})")
    end
  end

  describe "#uid_regexp" do
    it "matches the various forms of the UID" do
      expect(subject.uid_regexp.match?("#{name}")).to be true
      expect(subject.uid_regexp.match?("#{name} (#{version})")).to be true
      expect(subject.uid_regexp.match?("other-dep (other-version)")).to be false
    end
  end

  describe "#has_exception?" do
    context "when dependency has exceptions" do
      before do
        LicenseScout::Config.exceptions.ruby = [{ "name" => name }]
      end

      it "returns true" do
        expect(subject.has_exception?).to be true
      end
    end

    context "when dependency has no exceptions" do
      it "returns false" do
        expect(subject.has_exception?).to be false
      end
    end
  end

  describe "#exception_reason" do
    context "when there is no exception" do
      it "returns nil" do
        expect(subject.exception_reason).to be_nil
      end
    end

    context "when there is an exception but no reason" do
      before do
        LicenseScout::Config.exceptions.ruby = [{ "name" => name }]
      end

      it "returns nil" do
        expect(subject.exception_reason).to be_nil
      end
    end

    context "when there is an exception with a reason" do
      let(:reason) { "Reason why there is an exception" }
      before do
        LicenseScout::Config.exceptions.ruby = [{ "name" => name, "reason" => reason }]
      end

      it "returns the reason" do
        expect(subject.exception_reason).to eql(reason)
      end
    end
  end

end
