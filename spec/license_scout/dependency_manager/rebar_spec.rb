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

RSpec.describe LicenseScout::DependencyManager::Rebar do

  let(:subject) { described_class.new(directory) }
  let(:directory) { "/some/random/directory" }

  let(:rebar_config_path) { File.join(directory, "rebar.config") }

  describe ".new" do
    it "creates new instance of a dependency manager" do
      expect(subject.directory).to eql(directory)
    end
  end

  describe "#name" do
    it "equals 'erlang_rebar'" do
      expect(subject.name).to eql("erlang_rebar")
    end
  end

  describe "#type" do
    it "equals 'erlang'" do
      expect(subject.type).to eql("erlang")
    end
  end

  describe "#signature" do
    it "equals 'rebar.config file'" do
      expect(subject.signature).to eql("rebar.config file")
    end
  end

  describe "#install_command" do
    it "returns 'rebar get-deps'" do
      expect(subject.install_command).to eql("rebar get-deps")
    end
  end

  describe "#detected?" do
    let(:rebar_config_exists) { true }

    before do
      expect(File).to receive(:exist?).with(rebar_config_path).and_return(rebar_config_exists)
    end

    context "when rebar.config exists" do
      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when rebar.config is missing" do
      let(:rebar_config_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end
  end

  describe "#dependencies" do

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

    def mock_git_rev_parse_for(name, sha, cwd: File.join(directory, "deps", name))
      mock = instance_double("Mixlib::ShellOut")

      allow(Mixlib::ShellOut).to receive(:new)
        .with("git rev-parse HEAD", cwd: cwd)
        .and_return(mock)

      allow(mock).to receive(:run_command)
      allow(mock).to receive(:error!)
      allow(mock).to receive(:stdout).and_return("#{sha}\n")
    end

    before do
      dependency_git_shas.each do |name, sha|
        mock_git_rev_parse_for(name, sha)
      end
    end

    context "when given a real rebar project" do
      let(:directory) { File.join(SPEC_FIXTURES_DIR, "rebar") }

      it "returns an array of Dependencies found in the directory" do
        deps = subject.dependencies
        expect(deps.size).to eq(dependency_git_shas.size)

        expected_names = dependency_git_shas.keys

        expect(deps.map(&:name)).to match_array(expected_names)

        deps.each do |dep|
          expect(dep.version).to eql(dependency_git_shas[dep.name])
        end

        # Make sure we detected all of the license types, except for bcrypt,
        # bcrypt's license file is non-standard:
        deps_with_license_files = deps.select { |d| !d.license.records.empty? }
        expect(deps_with_license_files.size).to eql(32)

        undetected_licenses = deps_with_license_files.select { |d| d.license.records.first.id.nil? }
        expect(undetected_licenses.size).to eql(5)
        expect(undetected_licenses.map(&:name)).to include("bcrypt")

        # Spot check some licenses:
        ej = deps.find { |d| d.name == "ej" }
        expect(ej.license.records.first.id).to eql("Apache-2.0")
        expect(ej.license.records.first.source).to eql("LICENSE")

        gen_bunny = deps.find { |d| d.name == "gen_bunny" }
        expect(gen_bunny.license.records.first.id).to eql("MIT")
        expect(gen_bunny.license.records.first.source).to eql("LICENSE")

        bcrypt = deps.find { |d| d.name == "bcrypt" }
        expect(bcrypt.license.records.first.id).to be_nil
        expect(bcrypt.license.records.first.source).to eql("LICENSE")
      end
    end

    context "when given a build directory" do
      let(:directory) { File.join(SPEC_FIXTURES_DIR, "rebar_from_build") }
      let(:expected_rebar_lock_json_output) { '{"bifrost":{"type":"git","level":0,"git_url":"https:\/\/github.com\/chef\/bifrost-yeah-not-really","git_ref":"9e47ba9fc8a31aa2a4f9317de69b677fa34eb17e"},"edown":{"type":"git","level":0,"git_url":"https:\/\/github.com\/uwiger\/edown.git","git_ref":"754be25f71a04099c83f3ffdff268e70beeb0021"},"mochiweb":{"type":"pkg","level":0,"pkg_name":"mochiweb","pkg_version":"2.12.2","pkg_hash":"087467DE5833C0BB5B3CCDD387F9E9C1FB816A75B7A709629BF24B5ED3246C51"}}' }

      def mock_rebar_lock_json
        rebar_lock_json_path = File.expand_path("../../../bin/rebar_lock_json", File.dirname(__FILE__))
        rebar_lock_path = File.join(directory, "rebar.lock")
        mock = instance_double("Mixlib::ShellOut")

        allow(Mixlib::ShellOut).to receive(:new)
          .with("#{LicenseScout::Config.escript_bin} #{rebar_lock_json_path} #{rebar_lock_path}", environment: {})
          .and_return(mock)

        allow(mock).to receive(:run_command)
        allow(mock).to receive(:error!)
        allow(mock).to receive(:stdout).and_return(expected_rebar_lock_json_output)
      end

      before do
        mock_rebar_lock_json
        mock_git_rev_parse_for(
          "edown", "30a9f7867d615af45783235faa52742d11a9348e",
          cwd: File.join(directory, "_build/default/lib/edown")
        )
        mock_git_rev_parse_for(
          "eper",
          "43e0442863df9f713a5c88c9b43062b806d96adb",
          cwd: File.join(directory, "_build/default/lib/eper")
        )
      end

      it "returns an array of Dependencies found in the directory" do
        dependencies = subject.dependencies
        expect(dependencies.length).to eql(3)

        bifrost = dependencies.find { |d| d.name == "bifrost" }
        expect(bifrost).to be_nil

        mochiweb = dependencies.find { |d| d.name == "mochiweb" }
        expect(mochiweb.version).to eql("2.12.2")
        expect(mochiweb.license.records.first.id).to be_nil
        expect(mochiweb.license.records.first.source).to eql("LICENSE")

        eper = dependencies.find { |d| d.name == "eper" }
        expect(eper.version).to eq("43e0442863df9f713a5c88c9b43062b806d96adb")
        expect(eper.license.records.first.id).to eql("MIT")
        expect(eper.license.records.first.source).to eql("COPYING")

        edown = dependencies.find { |d| d.name == "edown" }
        expect(edown.version).to eq("30a9f7867d615af45783235faa52742d11a9348e")
        expect(edown.license.records).to be_empty
      end
    end
  end
end
