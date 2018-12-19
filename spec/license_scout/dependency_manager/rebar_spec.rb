#
# Copyright:: Copyright 2016, Chef Software Inc.
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

require "license_scout/dependency_manager/rebar"
require "license_scout/overrides"
require "license_scout/options"

RSpec.describe(LicenseScout::DependencyManager::Rebar) do

  let(:dependency_git_shas) do
    {
      "amqp_client"             => "7622ad8093a41b7288a1aa44dd16d3e92ce8f833",
      "automeck"                => "363657b4dff5ef5561e77a7d44348abf11405d09",
      "bcrypt"                  => "820283b0d329368f298afd22038340c888689a39",
      "bear"                    => "119234548783af19b8ec75c879c5062676b92571",
      "chef_authn"              => "e7850d0925b01761d8085ee8b44dafbbe1b297a4",
      "darklaunch"              => "05881cb04e9393ab42b6fac3b22803130ef2701c",
      "edown"                   => "30a9f7867d615af45783235faa52742d11a9348e",
      "ej"                      => "132a9a3c0662a2377eaf7ebee694a496a0957160",
      "envy"                    => "e6ba39664a1016ed309ea44269247943de2eb16b",
      "eper"                    => "80e7cd6446d26d2423f2acd37253826bb3152964",
      "epgsql"                  => "cdb859d0d54fc4bed2107fd3d197bc7ea815958f",
      "erlware_commons"         => "2e23e43079686ddb68bfca772d37f78dfe4dd95e",
      "folsom"                  => "38e2cce7c64ce1f0a3a918d90394cfc0a940b1ba",
      "folsom_graphite"         => "d4ce9bf02c025ca559d18abc084c367bf4deaf3f",
      "gen_bunny"               => "fe10af39cd4ad8de7a8d6a0d90f79ea73e788761",
      "gen_server2"             => "992650004c81ee921183488cb8115de4777e7bd9",
      "goldrush"                => "71e63212f12c25827e0c1b4198d37d5d018a7fec",
      "ibrowse"                 => "8f3f6a3a30730b193cc340a8885a960586dc98de",
      "jiffy"                   => "2f405e2b9ae3c2a9cf59ab10179c3262cf4aff03",
      "lager"                   => "d33ccf3b69de09a628fe38b4d7981bb8671b8a4f",
      "meck"                    => "8de4a66bfd33d05f090b930b4e90d64b89b6e9cb",
      "mini_s3"                 => "1cf296868077caefa6791f4996145a369c49091b",
      "mixer"                   => "58ded93d5c47675899d8e5e1589270f340ea66c5",
      "mochiweb"                => "ade2a9b29a11034eb550c1d79b4f991bf5ca05ba",
      "neotoma"                 => "760928ec8870da02eb11bccb501e2700925d06c6",
      "opscoderl_folsom"        => "d493429f895a904e9fd86d12a68f7075dfa8e227",
      "opscoderl_httpc"         => "2f0e99cadbe80b5c728109ff669a5efb164ab79e",
      "opscoderl_wm"            => "64db62e070da58cf7bb0caebde7a3f11c2e3cbbb",
      "pooler"                  => "7bb8ab83c6f60475e6ef8867d3d5afa0b1dd4013",
      "quickrand"               => "0395a10b94472ccbe38b62bbfa9d0fc1ddac1dd7",
      "rabbit_common"           => "4388fe57cb63872f5fcf3a2670b4f05de657a64b",
      "rebar_lock_deps_plugin"  => "7a5835029c42b8138325405237ea7e8516a84800",
      "rebar_vsn_plugin"        => "fd40c960c7912193631d948fe962e1162a8d1334",
      "sqerl"                   => "17d8d95dbb644d20af3ab7dc19d04dab14e4bed5",
      "stats_hero"              => "ff000415e5ca71d7ffcfea15153bd696a386455a",
      "sync"                    => "ae7dbd4e6e2c08d77d96fc4c2bc2b6a3b266492b",
      "uuid"                    => "f7c141c8359cd690faba0d2684b449a07db8e915",
      "webmachine"              => "7677c240f4a7ed020f4bab48278224966bb42311",
    }
  end

  subject(:rebar) do
    described_class.new(project_dir, LicenseScout::Options.new(
      overrides: overrides
    ))
  end

  let(:tmpdir) { Dir.mktmpdir }

  let(:overrides) do
    o = LicenseScout::Overrides.new(exclude_default: true)
    # delete the default erlang overrides
    o.override_rules.delete("erlang_rebar")
    o
  end

  let(:project_dir) { File.join(tmpdir, "rebar_project") }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  it "has a name" do
    expect(rebar.name).to eq("erlang_rebar")
  end

  it "has a project directory" do
    expect(rebar.project_dir).to eq(project_dir)
  end

  describe "when provided a rebar project" do
    before do
      Dir.mkdir(project_dir)
      FileUtils.touch(File.join(project_dir, "rebar.config"))
    end

    it "detects a rebar project correctly" do
      expect(rebar.detected?).to eq(true)
    end
  end

  describe "when provided a non-rebar project" do
    before do
      Dir.mkdir(project_dir)
    end

    it "does not detect the project" do
      expect(rebar.detected?).to eq(false)
    end
  end

  describe "when provided a real rebar project" do

    let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "rebar") }

    def mock_git_rev_parse_for(name, sha, cwd: File.join(project_dir, "deps", name))
      mock = instance_double("Mixlib::ShellOut")

      allow(Mixlib::ShellOut).to receive(:new)
        .with("git rev-parse HEAD", cwd: cwd)
        .and_return(mock)

      allow(mock).to receive(:run_command)
      allow(mock).to receive(:error!)
      allow(mock).to receive(:stdout).and_return("#{sha}\n")
    end

    def expand_fixture_path(relpath)
      File.join(project_dir, relpath)
    end

    before do
      dependency_git_shas.each do |name, sha|
        mock_git_rev_parse_for(name, sha)
      end
    end

    it "detects the licenses of the transitive dependencies correctly" do
      deps = rebar.dependencies
      expect(deps.size).to eq(dependency_git_shas.size)

      expected_names = dependency_git_shas.keys

      expect(deps.map(&:name)).to match_array(expected_names)

      deps.each do |dep|
        expect(dep.version).to eq(dependency_git_shas[dep.name])
      end

      # Make sure we detected all of the license types, except for bcrypt,
      # bcrypt's license file is non-standard:
      deps_with_license_files = deps.select { |d| !d.license_files.empty? }
      expect(deps_with_license_files.size).to eq(29)

      undetected_licenses = deps_with_license_files.select { |d| d.license.nil? }
      expect(undetected_licenses.size).to eq(1)
      expect(undetected_licenses.first.name).to eq("bcrypt")

      # Spot check some licenses:
      ej = deps.find { |d| d.name == "ej" }
      expect(ej.license_files).to eq([expand_fixture_path("deps/ej/LICENSE")])
      expect(ej.license).to eq("Apache-2.0")

      gen_bunny = deps.find { |d| d.name == "gen_bunny" }
      expect(gen_bunny.license_files).to eq([expand_fixture_path("deps/gen_bunny/LICENSE")])
      expect(gen_bunny.license).to eq("MIT")

      bcrypt = deps.find { |d| d.name == "bcrypt" }
      expect(bcrypt.license_files).to eq([expand_fixture_path("deps/bcrypt/LICENSE")])
      expect(bcrypt.license).to be_nil
    end

    describe "when only license files are overridden." do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "erlang_rebar", "ej" do |version|
            {
              license_files: [ "Makefile" ], # pick any file from ej
            }
          end
        end
      end

      it "only uses license file overrides and reports the original license" do
        dependencies = rebar.dependencies
        expect(dependencies.length).to eq(38)

        ej = dependencies.find { |d| d.name == "ej" }
        expect(ej.version).to eq("132a9a3c0662a2377eaf7ebee694a496a0957160")

        # We detect license type from the license file. This is applied before
        # we scan the licenses. Since we set the license file to a file that's
        # not a license in this test, we should not detect its type
        expect(ej.license).to be_nil
        expect(ej.license_files.length).to eq(1)
        expect(ej.license_files.first).to eq(expand_fixture_path("deps/ej/Makefile"))
      end
    end

    describe "when overrides for both license file and type are given" do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "erlang_rebar", "ej" do |version|
            {
              license: "example-license",
              license_files: [ "Makefile" ],
            }
          end
        end
      end

      it "uses the given overrides" do
        dependencies = rebar.dependencies
        expect(dependencies.length).to eq(38)

        ej = dependencies.find { |d| d.name == "ej" }
        expect(ej.version).to eq("132a9a3c0662a2377eaf7ebee694a496a0957160")
        expect(ej.license).to eq("example-license")
        expect(ej.license_files.length).to eq(1)
        expect(ej.license_files.first).to eq(expand_fixture_path("deps/ej/Makefile"))
      end
    end

    describe "when overrides with missing license file paths are provided" do
      let(:overrides) do
        LicenseScout::Overrides.new(exclude_default: true) do
          override_license "erlang_rebar", "ej" do |version|
            {
              license: "Apache",
              license_files: [ "NOPE-LICENSE" ],
            }
          end
        end
      end

      it "raises an error" do
        expect { rebar.dependencies }.to raise_error(LicenseScout::Exceptions::InvalidOverride)
      end
    end

    describe "as in an automated build" do

      let(:project_dir) { File.join(SPEC_FIXTURES_DIR, "rebar_from_build") }
      let(:expected_rebar_lock_json_output) { '{"bifrost":{"type":"git","level":0,"git_url":"https:\/\/github.com\/chef\/bifrost-yeah-not-really","git_ref":"9e47ba9fc8a31aa2a4f9317de69b677fa34eb17e"},"edown":{"type":"git","level":0,"git_url":"https:\/\/github.com\/uwiger\/edown.git","git_ref":"754be25f71a04099c83f3ffdff268e70beeb0021"},"mochiweb":{"type":"pkg","level":0,"pkg_name":"mochiweb","pkg_version":"2.12.2","pkg_hash":"087467DE5833C0BB5B3CCDD387F9E9C1FB816A75B7A709629BF24B5ED3246C51"}}' }

      def mock_rebar_lock_json
        rebar_lock_json_path = File.expand_path("../../../bin/rebar_lock_json", File.dirname(__FILE__))
        rebar_lock_path = File.join(project_dir, "rebar.lock")
        mock = instance_double("Mixlib::ShellOut")

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{rebar_lock_json_path} #{rebar_lock_path}", environment: {})
          .and_return(mock)

        allow(mock).to receive(:run_command)
        allow(mock).to receive(:error!)
        allow(mock).to receive(:stdout).and_return(expected_rebar_lock_json_output)
      end

      before do
        mock_rebar_lock_json
        mock_git_rev_parse_for(
          "edown", "30a9f7867d615af45783235faa52742d11a9348e",
          cwd: File.join(project_dir, "_build/default/lib/edown")
        )
        mock_git_rev_parse_for(
          "eper",
          "43e0442863df9f713a5c88c9b43062b806d96adb",
          cwd: File.join(project_dir, "_build/default/lib/eper")
        )
      end

      it "discovers the license information correctly" do
        dependencies = rebar.dependencies
        expect(dependencies.length).to eq(3)

        bifrost = dependencies.find { |d| d.name == "bifrost" }
        expect(bifrost).to be_nil

        mochiweb = dependencies.find { |d| d.name == "mochiweb" }
        expect(mochiweb.license).to eq("MIT")
        expect(mochiweb.version).to eq("2.12.2")
        expect(mochiweb.license_files.length).to eq(1)
        expect(mochiweb.license_files.first).to end_with("_build/default/lib/mochiweb/LICENSE")

        eper = dependencies.find { |d| d.name == "eper" }
        expect(eper.license).to eq("MIT")
        expect(eper.version).to eq("43e0442863df9f713a5c88c9b43062b806d96adb")
        expect(eper.license_files.length).to eq(1)
        expect(eper.license_files.first).to end_with("_build/default/lib/eper/COPYING")

        edown = dependencies.find { |d| d.name == "edown" }
        expect(edown.license).to be_nil
        expect(edown.version).to eq("30a9f7867d615af45783235faa52742d11a9348e")
        expect(edown.license_files).to be_empty

      end

    end

  end

end
