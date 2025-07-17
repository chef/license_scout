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

RSpec.describe LicenseScout::DependencyManager::Bundler do
  let(:subject) { described_class.new(directory) }
  let(:directory) { '/some/random/directory' }

  let(:gemfile_path) { File.join(directory, 'Gemfile') }
  let(:gemfile_lock_path) { File.join(directory, 'Gemfile.lock') }

  describe '.new' do
    it 'creates new instance of a dependency manager' do
      expect(subject.directory).to eql(directory)
    end
  end

  describe '#name' do
    it "equals 'ruby_bundler'" do
      expect(subject.name).to eql('ruby_bundler')
    end
  end

  describe '#type' do
    it "equals 'ruby'" do
      expect(subject.type).to eql('ruby')
    end
  end

  describe '#signature' do
    it "equals 'Gemfile and Gemfile.lock files'" do
      expect(subject.signature).to eql('Gemfile and Gemfile.lock files')
    end
  end

  describe '#install_command' do
    it "returns 'bundle install'" do
      expect(subject.install_command).to eql('bundle install')
    end
  end

  describe '#detected?' do
    let(:gemfile_exists) { true }
    let(:gemfile_lock_exists) { true }

    before do
      expect(File).to receive(:exist?).with(gemfile_path).and_return(gemfile_exists)
      expect(File).to receive(:exist?).with(gemfile_lock_path).and_return(gemfile_lock_exists)
    end

    context 'when Gemfile and Gemfile.lock exist' do
      it 'returns true' do
        expect(subject.detected?).to be true
      end
    end

    context 'when either Gemfile or Gemfile.lock is missing' do
      let(:gemfile_exists) { true }
      let(:gemfile_lock_exists) { false }

      it 'returns false' do
        expect(subject.detected?).to be false
      end
    end
  end

  describe '#dependencies', :vcr do
    let(:directory) { '/fake/project' }
    let(:subject) { described_class.new(directory) }
    let(:bundler_path) { 'https://github.com/bundler/bundler' }
    let(:json_path) { 'https://github.com/flori/json' }
    let(:other_path) { '/some/path/to/gem' }

    before do
      allow(subject).to receive(:new_dependency) do |name, version, path|
        double(name:, version:, path:, add_license: nil)
      end
    end

    context 'when dependency_data is empty' do
      before { allow(subject).to receive(:dependency_data).and_return([]) }

      it 'returns an empty array' do
        expect(subject.dependencies).to eq([])
      end
    end

    context 'when dependency_data contains a regular gem' do
      let(:dependency_data) do
        [
          { 'name' => 'rake', 'version' => '13.0.6', 'license' => 'MIT', 'path' => other_path }
        ]
      end

      before { allow(subject).to receive(:dependency_data).and_return(dependency_data) }

      it 'returns dependency objects with correct attributes' do
        deps = subject.dependencies
        expect(deps.size).to eq(1)
        expect(deps.first.name).to eq('rake')
        expect(deps.first.version).to eq('13.0.6')
        expect(deps.first.path).to eq(other_path)
        expect(deps.first).to have_received(:add_license).with('MIT', 'https://rubygems.org/gems/rake/versions/13.0.6')
      end
    end

    context 'when dependency_data contains bundler gem' do
      let(:dependency_data) do
        [
          { 'name' => 'bundler', 'version' => '2.3.10', 'license' => 'MIT', 'path' => '/weird/path' }
        ]
      end

      before { allow(subject).to receive(:dependency_data).and_return(dependency_data) }

      it 'sets the path to the bundler github url' do
        deps = subject.dependencies
        expect(deps.first.path).to eq(bundler_path)
        expect(deps.first).to have_received(:add_license).with('MIT', 'https://rubygems.org/gems/bundler/versions/2.3.10')
      end
    end

    context 'when dependency_data contains json gem' do
      let(:dependency_data) do
        [
          { 'name' => 'json', 'version' => '2.6.3', 'license' => nil,
            'path' => '/opt/opscode/embedded/lib/ruby/2.2.0/json.rb' }
        ]
      end

      before { allow(subject).to receive(:dependency_data).and_return(dependency_data) }

      it 'sets the path to the json github url and does not add license' do
        deps = subject.dependencies
        expect(deps.first.path).to eq(json_path)
        expect(deps.first).not_to have_received(:add_license)
      end
    end

    context 'when dependency_data contains a gem with nil license' do
      let(:dependency_data) do
        [
          { 'name' => 'nokogiri', 'version' => '1.13.3', 'license' => nil, 'path' => other_path }
        ]
      end

      before { allow(subject).to receive(:dependency_data).and_return(dependency_data) }

      it 'does not add a license' do
        deps = subject.dependencies
        expect(deps.first).not_to have_received(:add_license)
      end
    end
  end
end
