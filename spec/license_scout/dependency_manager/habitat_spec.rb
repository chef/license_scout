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

RSpec.describe LicenseScout::DependencyManager::Habitat do

  let(:subject) { described_class.new(directory) }
  let(:directory) { "/some/random/directory" }

  let(:plan_sh_path) { File.join(directory, "plan.sh") }
  let(:habitat_plan_sh_path) { File.join(directory, "habitat", "plan.sh") }

  let(:plan_sh_exists) { true }
  let(:habitat_plan_sh_exists) { false }

  describe ".new" do
    it "creates new instance of a dependency manager" do
      expect(subject.directory).to eql(directory)
    end
  end

  describe "#name" do
    it "equals 'habitat'" do
      expect(subject.name).to eql("habitat")
    end
  end

  describe "#type" do
    it "equals 'habitat'" do
      expect(subject.type).to eql("habitat")
    end
  end

  describe "#signature" do
    before do
      allow(File).to receive(:exist?).with(plan_sh_path).and_return(plan_sh_exists)
      allow(File).to receive(:exist?).with(habitat_plan_sh_path).and_return(habitat_plan_sh_exists)
    end

    context "when plan.sh file exists" do
      it "equals 'plan.sh file'" do
        expect(subject.signature).to eql("plan.sh file")
      end
    end

    context "when habitat/plan.sh file exists" do
      let(:plan_sh_exists) { false }
      let(:habitat_plan_sh_exists) { true }

      it "equals 'plan.sh file'" do
        expect(subject.signature).to eql("habitat/plan.sh file")
      end
    end
  end

  describe "#install_command" do
    it "returns ''" do
      expect(subject.install_command).to eql("")
    end
  end

  describe "#detected?" do
    before do
      allow(File).to receive(:exist?).with(plan_sh_path).and_return(plan_sh_exists)
      allow(File).to receive(:exist?).with(habitat_plan_sh_path).and_return(habitat_plan_sh_exists)
    end

    context "when plan.sh exists" do
      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when a habitat/plan.sh exists" do
      let(:plan_sh_exists) { false }
      let(:habitat_plan_sh_exists) { true }

      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when plan.sh is missing" do
      let(:plan_sh_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end
  end

  describe "#dependencies", :vcr do

    context "when a plan.sh is found" do
      let(:directory) { File.join(SPEC_FIXTURES_DIR, "habitat") }

      it "returns an array of Dependencies found in the directory" do
        dependencies = subject.dependencies

        # Make sure we have the right count
        expect(dependencies.length).to eq(3)

        glibc = dependencies.find { |d| d.name == "core/glibc" }
        linux_headers = dependencies.find { |d| d.name == "core/linux-headers" }

        expect(glibc.version).to eq("2.22-20170513201042")
        expect(glibc.license.records.first.id).to eql("GPL-2.0")
        expect(glibc.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/glibc/2.22/20170513201042")

        expect(linux_headers.version).to eq("4.3-20170513200956")
        expect(linux_headers.license.records.first.id).to eql("GPL-2.0")
        expect(linux_headers.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/linux-headers/4.3/20170513200956")
      end
    end

    context "when a habitat/plan.sh is found" do
      let(:directory) { File.join(SPEC_FIXTURES_DIR, "nested_hab") }

      it "returns an array of Dependencies found in the directory" do
        dependencies = subject.dependencies

        # Make sure we have the right count
        expect(dependencies.length).to eq(2)

        glibc = dependencies.find { |d| d.name == "core/glibc" }
        linux_headers = dependencies.find { |d| d.name == "core/linux-headers" }

        expect(glibc.version).to eq("2.22-20170513201042")
        expect(glibc.license.records.first.id).to eql("GPL-2.0")
        expect(glibc.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/glibc/2.22/20170513201042")

        expect(linux_headers.version).to eq("4.3-20170513200956")
        expect(linux_headers.license.records.first.id).to eql("GPL-2.0")
        expect(linux_headers.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/linux-headers/4.3/20170513200956")
      end
    end
  end
end