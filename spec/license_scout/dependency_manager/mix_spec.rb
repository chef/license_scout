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

RSpec.describe LicenseScout::DependencyManager::Mix do
  let(:directory) { '/some/random/directory' }
  let(:subject) { described_class.new(directory) }

  let(:mix_lock_path) { File.join(directory, 'mix.lock') }

  describe '.new' do
    it 'creates new instance of a dependency manager' do
      expect(subject.directory).to eql(directory)
    end
  end

  describe '#name' do
    it "equals 'elixir_mix'" do
      expect(subject.name).to eql('elixir_mix')
    end
  end

  describe '#type' do
    it "equals 'elixir'" do
      expect(subject.type).to eql('elixir')
    end
  end

  describe '#signature' do
    it "equals 'mix.lock file'" do
      expect(subject.signature).to eql('mix.lock file')
    end
  end

  describe '#install_command' do
    it "returns 'mix deps'" do
      expect(subject.install_command).to eql('mix deps.get')
    end
  end

  describe '#detected?' do
    let(:mix_lock_exists) { true }

    before do
      expect(File).to receive(:exist?).with(mix_lock_path).and_return(mix_lock_exists)
    end

    context 'when mix.lock exists' do
      it 'returns true' do
        expect(subject.detected?).to be true
      end
    end

    context 'when mix.lock is missing' do
      let(:mix_lock_exists) { false }

      it 'returns false' do
        expect(subject.detected?).to be false
      end
    end
  end

  # describe "#dependencies", :vcr do
  #   let(:directory) { File.join(SPEC_FIXTURES_DIR, "mix") }

  #   it "returns an array of Dependencies found in the directory", :no_windows do
  #     dependencies = subject.dependencies

  #     # Make sure we have the right count
  #     expect(dependencies.length).to eq(4)

  #     earmark = dependencies.find { |d| d.name == "earmark" }
  #     ex_doc = dependencies.find { |d| d.name == "ex_doc" }

  #     expect(earmark.version).to eq("1.2.5")
  #     expect(earmark.license.records.first.id).to eql("Apache-2.0")
  #     expect(earmark.license.records.first.source).to eql("README.md")

  #     expect(ex_doc.version).to eq("0.18.3")
  #     expect(ex_doc.license.records.first.id).to be_nil
  #     expect(ex_doc.license.records.first.source).to eql("LICENSE")
  #     expect(ex_doc.license.records[1].id).to eql("Apache-2.0")
  #     expect(ex_doc.license.records[1].source).to eql("https://hex.pm/api/packages/ex_doc")
  #   end
  # end

  describe '#dependencies', :vcr do
    let(:subject) { described_class.new(directory) }
    let(:directory) { '/fake/project' }

    before do
      allow(subject).to receive(:parse_packaged_dependencies)
    end

    context 'when packaged_dependencies is empty' do
      before do
        allow(subject).to receive(:packaged_dependencies).and_return({})
      end

      it 'returns an empty array' do
        expect(subject.dependencies).to eq([])
      end
    end

    context 'when packaged_dependencies has entries' do
      let(:packaged_deps) { { 'dep1' => '1.0.0', 'dep2' => '2.0.0' } }
      let(:dep1_path) { '/fake/project/deps/dep1' }
      let(:dep2_path) { '/fake/project/deps/dep2' }

      before do
        allow(subject).to receive(:packaged_dependencies).and_return(packaged_deps)
        allow(Dir).to receive(:glob).with(File.join(directory, '**', 'deps', 'dep1')).and_return([dep1_path])
        allow(Dir).to receive(:glob).with(File.join(directory, '**', 'deps', 'dep2')).and_return([dep2_path])
        allow(subject).to receive(:new_dependency) do |name, version, path|
          double(name:, version:, path:, add_license: nil)
        end
        allow(subject).to receive(:hex_info).with('dep1').and_return({ 'meta' => { 'licenses' => ['MIT'] } })
        allow(subject).to receive(:hex_info).with('dep2').and_return({ 'meta' => { 'licenses' => ['Apache-2.0',
                                                                                                  'BSD'] } })
      end

      it 'returns dependency objects with correct attributes' do
        deps = subject.dependencies
        expect(deps.size).to eq(2)
        expect(deps.map(&:name)).to contain_exactly('dep1', 'dep2')
        expect(deps.map(&:version)).to contain_exactly('1.0.0', '2.0.0')
        expect(deps.map(&:path)).to contain_exactly(dep1_path, dep2_path)
      end

      it 'adds licenses to each dependency' do
        deps = subject.dependencies
        expect(deps[0]).to have_received(:add_license).with('MIT', 'https://hex.pm/api/packages/dep1')
        expect(deps[1]).to have_received(:add_license).with('Apache-2.0', 'https://hex.pm/api/packages/dep2')
        expect(deps[1]).to have_received(:add_license).with('BSD', 'https://hex.pm/api/packages/dep2')
      end
    end

    context 'when a dependency path is missing' do
      let(:packaged_deps) { { 'dep1' => '1.0.0' } }

      before do
        allow(subject).to receive(:packaged_dependencies).and_return(packaged_deps)
        allow(Dir).to receive(:glob).with(File.join(directory, '**', 'deps', 'dep1')).and_return([])
        allow(subject).to receive(:new_dependency).and_return(nil)
        allow(subject).to receive(:hex_info).with('dep1').and_return({ 'meta' => { 'licenses' => ['MIT'] } })
      end
    end
  end
end
