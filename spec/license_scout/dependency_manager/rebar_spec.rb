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
      "webmachine"              => "7677c240f4a7ed020f4bab48278224966bb42311"
    }
  end

end
