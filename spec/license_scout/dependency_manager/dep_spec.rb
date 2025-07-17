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

RSpec.describe LicenseScout::DependencyManager::Dep do
  let(:subject) { described_class.new(directory) }
  let(:directory) { '/some/random/directory' }

  let(:gopkg_lock_path) { File.join(directory, 'Gopkg.lock') }

  describe '.new' do
    it 'creates new instance of a dependency manager' do
      expect(subject.directory).to eql(directory)
    end
  end

  describe '#name' do
    it "equals 'golang_dep'" do
      expect(subject.name).to eql('golang_dep')
    end
  end

  describe '#type' do
    it "equals 'golang'" do
      expect(subject.type).to eql('golang')
    end
  end

  describe '#signature' do
    it "equals 'Gopkg.lock file'" do
      expect(subject.signature).to eql('Gopkg.lock file')
    end
  end

  describe '#install_command' do
    it "returns 'dep ensure'" do
      expect(subject.install_command).to eql('dep ensure')
    end
  end

  describe '#detected?' do
    let(:gopkg_lock_exists) { true }

    before do
      expect(File).to receive(:exist?).with(gopkg_lock_path).and_return(gopkg_lock_exists)
    end

    context 'when Gopkg.lock exists' do
      it 'returns true' do
        expect(subject.detected?).to be true
      end
    end

    context 'when Gopkg.lock is missing' do
      let(:gopkg_lock_exists) { false }

      it 'returns false' do
        expect(subject.detected?).to be false
      end
    end
  end

  describe '#dependencies' do
    let(:directory) { File.join(SPEC_FIXTURES_DIR, 'dep') }
    let(:gopath) { File.join(SPEC_FIXTURES_DIR, 'deps_gopath') }

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

      dep_a = dependencies.find { |d| d.name == 'github.com/foo/bar' }
      dep_b = dependencies.find { |d| d.name == 'gopkg.in/foo/baz' }

      expect(dep_a.version).to eql('a4973d9a4225417aecf5d450a9522f00c1f7130f')
      expect(dep_a.license.records.first.id).to eql('Apache-2.0')
      expect(dep_a.license.records.first.source).to eql('LICENSE')

      expect(dep_b.version).to eql('v5.0.45')
      expect(dep_b.license.records.first.id).to be_nil
      expect(dep_b.license.records.first.source).to eql('LICENSE')
    end

    it 'also checks vendor/ for license files' do
      dependencies = subject.dependencies
      expect(dependencies.length).to eq(3)

      dep_c = dependencies.find { |d| d.name == 'github.com/f00/b4r' }
      expect(dep_c.version).to eq('v0.0.1')
      expect(dep_c.license.records.first.id).to eql('MIT')
      expect(dep_c.license.records.first.source).to eql('LICENSE')
    end
  end
end
