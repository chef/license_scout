#
# Copyright:: Copyright 2018 Chef Software, Inc.
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
    before do
      $habitat_pkg_info = {}
    end

    context "when an channel_for_origin is used" do
      let(:directory) { File.join(SPEC_FIXTURES_DIR, "habitat") }
      before do
        LicenseScout::Config.habitat.channel_for_origin = [{
                                                             "origin" => "core",
                                                             "channel" => "unstable",
                                                           }]
      end

      after do
        LicenseScout::Config.habitat.channel_for_origin = []
      end

      it "returns an array of Dependencies found in the directory" do
        dependencies = subject.dependencies

        # Make sure we have the right count
        expect(dependencies.length).to eq(3)

        glibc = dependencies.find { |d| d.name == "core/glibc" }
        linux_headers = dependencies.find { |d| d.name == "core/linux-headers" }

        expect(glibc.version).to eq("2.27-20180608041157")
        expect(glibc.license.records.first.id).to eql("GPL-2.0")
        expect(glibc.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/glibc/2.27/20180608041157")
        expect(subject.fetched_urls["core/glibc"]).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/glibc/2.27/20180608041157")

        expect(linux_headers.version).to eq("4.15.9-20180608041107")
        expect(linux_headers.license.records.first.id).to eql("GPL-2.0")
        expect(linux_headers.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/linux-headers/4.15.9/20180608041107")
        expect(subject.fetched_urls["core/linux-headers"]).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/linux-headers/4.15.9/20180608041107")
      end
    end

    # VCR's filenames are too long for windows
    # WHEN: channel_for_origin is configured, but some tdeps are not present in that origin
    context "when packages are not in channel_for_origin" do
      let(:directory) { File.join(SPEC_FIXTURES_DIR, "habitat") }
      before do
        LicenseScout::Config.habitat.channel_for_origin = [{
                                                             "origin" => "core",
                                                             "channel" => "froghornetsnest",
                                                           }]
      end

      after do
        LicenseScout::Config.habitat.channel_for_origin = []
      end

      # VCR filename workaround:
      # it returns an array of depdendencies with dependencies not present in
      # channel_for_origin fetched from the fallback origin
      it "returns an array of dependencies found in the directory" do
        dependencies = subject.dependencies

        # make sure we have the right count
        expect(dependencies.length).to eq(3)

        glibc = dependencies.find { |d| d.name == "core/glibc" }
        linux_headers = dependencies.find { |d| d.name == "core/linux-headers" }

        expect(glibc.version).to eq("2.27-20180608041157")
        expect(glibc.license.records.first.id).to eql("GPL-2.0")
        expect(glibc.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/glibc/2.27/20180608041157")
        expect(subject.fetched_urls["core/glibc"]).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/glibc/2.27/20180608041157")

        expect(linux_headers.version).to eq("4.15.9-20180608041107")
        expect(linux_headers.license.records.first.id).to eql("GPL-2.0")
        expect(linux_headers.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/linux-headers/4.15.9/20180608041107")
        expect(subject.fetched_urls["core/linux-headers"]).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/linux-headers/4.15.9/20180608041107")
      end
    end

    # VCR filename workaround:
    # when an channel_for_origin is used, packages are not in that origin, but full ident is given for deps
    context "when full ident is given for deps" do
      let(:directory) { File.join(SPEC_FIXTURES_DIR, "habitat-full-ident") }
      before do
        LicenseScout::Config.habitat.channel_for_origin = [{
                                                             "origin" => "core",
                                                             "channel" => "froghornetsnest",
                                                           }]
      end

      after do
        LicenseScout::Config.habitat.channel_for_origin = []
      end

      # it returns an array of dependencies found in the directory, fetching
      # dependencies specified by a full ident from the unstable channel
      it "returns an array of dependencies found in the directory" do
        dependencies = subject.dependencies

        # make sure we have the right count
        expect(dependencies.length).to eq(44)

        csc = dependencies.find { |d| d.name == "chef/chef-server-ctl" }

        expect(csc.version).to eq("12.17.49-20180503181308")
        expect(csc.license.records.first.id).to eql("Apache-2.0")
        expect(csc.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/chef/unstable/pkgs/chef-server-ctl/12.17.49/20180503181308")
        expect(subject.fetched_urls["chef/chef-server-ctl"]).to eql("https://bldr.habitat.sh/v1/depot/channels/chef/unstable/pkgs/chef-server-ctl/12.17.49/20180503181308")
      end
    end

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
        expect(glibc.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/glibc/2.22/20170513201042")
        expect(subject.fetched_urls["core/glibc"]).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/glibc/2.22/20170513201042")

        expect(linux_headers.version).to eq("4.3-20170513200956")
        expect(linux_headers.license.records.first.id).to eql("GPL-2.0")
        expect(linux_headers.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/linux-headers/4.3/20170513200956")
        expect(subject.fetched_urls["core/linux-headers"]).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/linux-headers/4.3/20170513200956")
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
        expect(glibc.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/glibc/2.22/20170513201042")
        expect(subject.fetched_urls["core/glibc"]).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/glibc/2.22/20170513201042")

        expect(linux_headers.version).to eq("4.3-20170513200956")
        expect(linux_headers.license.records.first.id).to eql("GPL-2.0")
        expect(linux_headers.license.records.first.source).to eql("https://bldr.habitat.sh/v1/depot/channels/core/unstable/pkgs/linux-headers/4.3/20170513200956")
        expect(subject.fetched_urls["core/linux-headers"]).to eql("https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/linux-headers/4.3/20170513200956")
      end
    end
  end
end
