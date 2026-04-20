# frozen_string_literal: true

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

RSpec.describe LicenseScout::DependencyManager::Gomod do
  let(:subject) { described_class.new(directory) }
  let(:directory) { '/some/random/directory' }

  let(:go_sum_file) { File.join(directory, 'go.sum') }

  describe '.new' do
    it 'creates new instance of a dependency manager' do
      expect(subject.directory).to eql(directory)
    end
  end

  describe '#name' do
    it "equals 'golang_modules'" do
      expect(subject.name).to eql('golang_modules')
    end
  end

  describe '#type' do
    it "equals 'golang'" do
      expect(subject.type).to eql('golang')
    end
  end

  describe '#signature' do
    it "equals 'go.sum file'" do
      expect(subject.signature).to eql('go.sum file')
    end
  end

  describe '#install_command' do
    it "returns 'go mod download'" do
      expect(subject.install_command).to eql('go mod download')
    end
  end

  describe '#detected?' do
    let(:go_sum_file_exists) { true }

    before do
      expect(File).to receive(:exist?).with(go_sum_file).and_return(go_sum_file_exists)
    end

    context 'when go.sum exists' do
      it 'returns true' do
        expect(subject.detected?).to be true
      end
    end

    context 'when go.sum is missing' do
      let(:go_sum_file_exists) { false }

      it 'returns false' do
        expect(subject.detected?).to be false
      end
    end
  end

  describe '#dependencies' do
    let(:directory) { File.join(SPEC_FIXTURES_DIR, 'gomod') }

    before do
      Dir.chdir(directory) { `#{subject.install_command}` }
    end

    it 'returns an array of Dependencies found in the directory' do
      dependencies = subject.dependencies

      # Make sure we have the right count
      expect(dependencies.length).to eq(2)

      dep_a = dependencies.find { |d| d.name == 'github.com/klauspost/compress' }
      dep_b = dependencies.find { |d| d.name == 'github.com/oklog/ulid' }

      expect(dep_a.version).to eq('v1.10.3')
      expect(dep_a.license.records.first.id).to eql('BSD-3-Clause')
      expect(dep_a.license.records.first.source).to eql('LICENSE')

      expect(dep_b.version).to eq('v1.3.1')
      expect(dep_b.license.records.first.id).to eql('Apache-2.0')
      expect(dep_b.license.records.first.source).to eql('LICENSE')
    end
  end
  describe '#dependencies with vendored dependencies' do
    let(:directory) { File.join(SPEC_FIXTURES_DIR, 'gomod-vendor') }
    it 'returns an array of Dependencies found in the vendor directory' do
      dependencies = subject.dependencies
      expect(dependencies.length).to eq(1)
      dep = dependencies[0]
      expect(dep.version).to eq('v3.2.0+incompatible')
      expect(dep.license.records.first.id).to eql('MIT')
      expect(dep.license.records.first.source).to eql('LICENSE')
    end
  end
end
