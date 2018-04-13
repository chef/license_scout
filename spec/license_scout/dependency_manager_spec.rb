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

RSpec.describe LicenseScout::DependencyManager do

  describe ".implementations" do
    let(:subject) { described_class.implementations }
    let(:expected_implementations) do
      [
        described_class::Berkshelf,
        described_class::Bundler,
        described_class::Cpanm,
        described_class::Dep,
        described_class::Glide,
        described_class::Godep,
        described_class::Habitat,
        described_class::Mix,
        described_class::Rebar,
        described_class::Npm,
      ]
    end

    it { is_expected.to eql(expected_implementations) }
  end
end
