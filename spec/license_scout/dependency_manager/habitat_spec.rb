#
# Copyright:: Copyright 2017, Chef Software Inc.
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

require "license_scout/dependency_manager/habitat"

describe LicenseScout::DependencyManager::Habitat do
  subject(:hab_dep_man) { described_class.new project_dir, {} }
  let(:project_dir) { File.join SPEC_FIXTURES_DIR, "habitat" }

  describe "#name" do
    it "is 'habitat'" do
      expect(hab_dep_man.name).to eq "habitat"
    end
  end

  describe "#dependencies" do
    subject(:deps) { hab_dep_man.dependencies }

    it "is an array" do
      expect(deps).to be_an Array
    end

    context "when there are none" do
      let(:project_dir) { File.join SPEC_FIXTURES_DIR, "habitat_no_deps" }

      it "is an empty array" do
        expect(deps).to be_empty
      end
    end

    context "when there are some" do
      it "is an array of Dependency objects" do
        expect(deps).to all( be_a LicenseScout::Dependency )
      end

      context "a dependency" do
        subject(:dep) { deps.first }
        let(:glibc_ident_file) { double read: "core/glibc/2.22/20160612063629\n" }
        let(:linux_headers_ident_file) { double read: "core/linux-headers/4.3/20160612063537\n" }
        let(:manifest_file) { double read: "* __License__: gplv2" }

        before :each do
          allow(File).to receive(:open)

          allow(File).to receive(:open).with(
            "/hab/pkgs/core/glibc/2.22/20160612063629/IDENT"
          ).and_return(glibc_ident_file)

          allow(File).to receive(:open).with(
            "/hab/pkgs/core/glibc/2.22/20160612063629/MANIFEST"
          ).and_return(manifest_file)

          allow(File).to receive(:open).with(
            "/hab/pkgs/core/linux-headers/4.3/20160612063537/IDENT"
          ).and_return(linux_headers_ident_file)

          allow(File).to receive(:open).with(
            "/hab/pkgs/core/linux-headers/4.3/20160612063537/MANIFEST"
          ).and_return(manifest_file)
        end

        it "has a name" do
          expect(dep.name).to eq "core/glibc"
        end

        it "has a version" do
          expect(dep.version).to eq "2.22/20160612063629"
        end

        it "has a license" do
          expect(dep.license).to eq "gplv2"
        end

        it "has no license_files" do
          expect(dep.license_files).to be_empty
        end

        it "has a dependency manager name" do
          expect(dep.dep_mgr_name).to eq "habitat"
        end
      end
    end
  end

  describe "#detected?" do
    context "when the project_dir does not exist" do
      let(:project_dir) { File.join SPEC_FIXTURES_DIR, "not habitat" }

      it "is false" do
        expect(hab_dep_man.detected?).to be false
      end
    end

    context "when the project_dir does exist" do
      context "when an ident file does not exist in the project_dir" do
        let(:project_dir) { File.join SPEC_FIXTURES_DIR, "habitat_no_ident" }

        it "is false" do
          expect(hab_dep_man.detected?).to be false
        end
      end

      context "when an ident file exists in the project_dir" do
        context "when the ident file is not a proper ident" do
          let(:project_dir) { File.join SPEC_FIXTURES_DIR, "habitat_invalid" }

          it "is false" do
            expect(hab_dep_man.detected?).to be false
          end
        end

        context "when the ident file is a proper ident" do
          it "is true" do
            expect(hab_dep_man.detected?).to be true
          end
        end
      end
    end
  end
end
