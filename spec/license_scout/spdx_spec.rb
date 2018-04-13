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

RSpec.describe LicenseScout::SPDX do

  describe ".find" do

    context "for special cases" do
      it "handles the special cases" do
        described_class.send(:special_cases).each do |input, spdx|
          expect(described_class.find(input)).to eql(spdx)
        end
      end
    end

    context "for valid SPDX IDs" do
      it "passes them right through" do
        described_class.known_ids.each do |spdx|
          expect(described_class.find(spdx)).to eql(spdx)
        end
      end
    end

    context "for valid SPDX names" do
      it "returns the corresponding SPDX ID" do
        described_class.send(:licenses).reject { |l| l["isDeprecatedLicenseId"] }.each do |l|
          expect(described_class.find(l["name"])).to eql(l["licenseId"])
        end
      end
    end

    context "when force is passed" do
      let(:license_id) { "Some custom license, probably specified as a fallback" }

      it "returns the license ID as is" do
        expect(described_class.find(license_id, force: true)).to eql(license_id)
      end
    end
  end

  describe ".parse" do
    it "breaks up mutli-license strings into individual licenses" do
      expect(described_class.parse("(MIT AND Apache-2.0)")).to eql(["MIT", "Apache-2.0"])
      expect(described_class.parse("MIT")).to eql(["MIT"])
      expect(described_class.parse("FOO AND BAR")).to eql(%w{FOO BAR})
    end
  end

end
