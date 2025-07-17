# frozen_string_literal: true

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

RSpec.describe LicenseScout::DependencyManager::Godep do
  let(:subject) { described_class.new(directory) }
  let(:directory) { '/some/random/directory' }

  let(:godeps_json_path) { File.join(directory, 'Godeps/Godeps.json') }

  describe '.new' do
    it 'creates new instance of a dependency manager' do
      expect(subject.directory).to eql(directory)
    end
  end

  describe '#name' do
    it "equals 'golang_godep'" do
      expect(subject.name).to eql('golang_godep')
    end
  end

  describe '#type' do
    it "equals 'golang'" do
      expect(subject.type).to eql('golang')
    end
  end

  describe '#signature' do
    it "equals 'Godeps/Godeps.json file'" do
      expect(subject.signature).to eql('Godeps/Godeps.json file')
    end
  end

  describe '#install_command' do
    it "returns 'godep restore'" do
      expect(subject.install_command).to eql('godep restore')
    end
  end

  describe '#detected?' do
    let(:godeps_json_exists) { true }

    before do
      expect(File).to receive(:exist?).with(godeps_json_path).and_return(godeps_json_exists)
    end

    context 'when glide.lock exists' do
      it 'returns true' do
        expect(subject.detected?).to be true
      end
    end

    context 'when glide.lock is missing' do
      let(:godeps_json_exists) { false }

      it 'returns false' do
        expect(subject.detected?).to be false
      end
    end
  end

  describe '#dependencies' do
    let(:directory) { File.join(SPEC_FIXTURES_DIR, 'godep') }
    let(:gopath) { File.join(SPEC_FIXTURES_DIR, 'godeps_gopath') }

    before do
      ENV['GOPATH'] = gopath
    end

    after do
      ENV.delete('GOPATH')
    end

    it 'returns an array of Dependencies found in the directory' do
      dependencies = subject.dependencies

      # Make sure we have the right count
      expect(dependencies.length).to eq(3)

      dep_a = dependencies.find { |d| d.name == 'github.com/dep/a' }
      dep_b = dependencies.find { |d| d.name == 'github.com/dep/b' }
      dep_c = dependencies.find { |d| d.name == 'github.com/dep/c/subdir' }

      expect(dep_a.version).to eq('rev0')
      expect(dep_a.license.records.first.id).to be_nil
      expect(dep_a.license.records.first.source).to eql('LICENSE.txt')

      expect(dep_b.version).to eq('v1.0.0')
      expect(dep_b.license.records).to be_empty

      expect(dep_c.version).to eq('rev2')
      expect(dep_c.license.records.first.id).to be_nil
      expect(dep_c.license.records.first.source).to eql('LICENSE')
    end
  end
end
