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

RSpec.describe LicenseScout::DependencyManager::Base do
  let(:subject) { described_class.new(directory) }
  let(:directory) { '/some/random/directory' }

  describe '.new' do
    it 'creates new instance of a dependency manager' do
      expect(subject.directory).to eql(directory)
    end
  end

  describe '#name' do
    it 'raises an error' do
      expect do
        subject.name
      end.to raise_error(LicenseScout::Exceptions::Error, 'All DependencyManagers must have a `#name` method')
    end
  end

  describe '#type' do
    it 'raises an error' do
      expect do
        subject.type
      end.to raise_error(LicenseScout::Exceptions::Error, 'All DependencyManagers must have a `#type` method')
    end
  end

  describe '#signature' do
    it 'raises an error' do
      expect do
        subject.signature
      end.to raise_error(LicenseScout::Exceptions::Error,
                         'All DependencyManagers must have a `#signature` method')
    end
  end

  describe '#install_command' do
    it 'raises an error' do
      expect do
        subject.install_command
      end.to raise_error(LicenseScout::Exceptions::Error,
                         'All DependencyManagers must have a `#install_command` method')
    end
  end

  describe '#detected?' do
    it 'raises an error' do
      expect do
        subject.detected?
      end.to raise_error(LicenseScout::Exceptions::Error,
                         'All DependencyManagers must have a `#detected?` method')
    end
  end

  describe '#dependencies' do
    it 'returns an empty array' do
      expect(subject.dependencies).to eql([])
    end
  end
end
