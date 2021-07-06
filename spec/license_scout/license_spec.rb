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

# A good portion of this module is tested by the DependencyManager tests. These
# tests just cover the condition cases.

RSpec.describe LicenseScout::License do

  let(:spdx) { "Apache-2.0" }
  let(:source) { "LICENSE" }

  let(:dependency_path) { File.join(SPEC_FIXTURES_DIR, "empty_project") }
  let(:apache_license_content) { File.read(File.join(SPEC_FIXTURES_DIR, "empty_project", "LICENSE")) }
  let(:record) { described_class::Record.new(spdx, source, apache_license_content) }

  describe ".new" do
    let(:subject) { described_class.new(dependency_path) }

    before do
      allow(described_class::Record).to receive(:new).with(spdx, source, apache_license_content).and_return(record)
    end

    context "when path is nil" do
      let(:dependency_path) { nil }

      it "returns an empty License record" do
        expect(subject.project).to be_nil
        expect(subject.records).to be_empty
      end
    end

    context "when path is a URL or directory path" do
      it "returns a hydrated License record" do
        expect(subject.project).to be_a(Licensee::Projects::FSProject)
        expect(subject.records).to eql([record])
      end
    end
  end

  describe "#is_allowed?" do
    let(:subject) { described_class.new(dependency_path).is_allowed? }
    let(:allowed_licenses) { [] }

    before do
      LicenseScout::Config.allowed_licenses = allowed_licenses
    end

    context "when all of the licenses is allowed" do
      let(:allowed_licenses) { [spdx, "MIT"] }
      it { is_expected.to be true }
    end

    context "when at least one of the licenses is not allowed" do
      let(:allowed_licenses) { ["MIT"] }

      it { is_expected.to be false }
    end
  end

  describe "#is_flagged?" do
    let(:subject) { described_class.new(dependency_path).is_flagged? }
    let(:flagged_licenses) { [] }

    before do
      LicenseScout::Config.flagged_licenses = flagged_licenses
    end

    context "when at least one of the licenses is flagged" do
      let(:flagged_licenses) { [spdx] }

      it { is_expected.to be true }
    end

    context "when all of the licenses are not flagged" do
      let(:flagged_licenses) { ["MIT"] }

      it { is_expected.to be false }
    end
  end

  describe "#add_license" do
    let(:license_url) { "https://url/to/license" }
    let(:options) { { a: 42 } }

    subject { described_class.new(dependency_path) }

    it "downloads license body and adds a new record" do
      expect(URI).to receive(:open).with(license_url).and_return(StringIO.new(apache_license_content))

      subject.add_license(spdx, source, license_url, options)

      new_record = subject.records.last
      expect(new_record).not_to be_nil
      expect(new_record.id).to eq(spdx)
      expect(new_record.source).to eq(source)
      expect(new_record.content).to eq(apache_license_content)
    end
  end
end
