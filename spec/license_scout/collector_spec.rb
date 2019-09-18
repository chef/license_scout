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

RSpec.describe LicenseScout::Collector do
  let(:subject) { described_class.new }

  describe "#collect" do
    context "when there are no dependency managers detected" do
      before do
        LicenseScout::Config.directories = [ File.join(SPEC_FIXTURES_DIR, "empty_project") ]
      end

      it "raises an error" do
        expect { subject.collect }.to raise_error(LicenseScout::Exceptions::Error, /Failed to find any files associated with known dependency managers/)
      end
    end

    context "when one of the dependencies is missing a source directory" do
      before do
        LicenseScout::Config.directories = [ File.join(SPEC_FIXTURES_DIR, "godep") ]
      end

      it "raises an error" do
        expect { subject.collect }.to raise_error(LicenseScout::Exceptions::Error, /Please try running `godep restore`/)
      end
    end

    context "when one or more valid directories are specified", :vcr do
      before do
        LicenseScout::Config.directories = [ File.join(SPEC_FIXTURES_DIR, "habitat"), File.join(SPEC_FIXTURES_DIR, "empty_project") ]
      end

      it "collects all of the dependencies for all the supported implementations", :no_windows do
        subject.collect
        expect(subject.dependencies.length).to eql(3)
        expect(subject.dependencies.map(&:name)).to eql(["core/glibc", "core/linux-headers", "core/musl"])
      end
    end
  end
end
