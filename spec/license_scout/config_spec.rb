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

RSpec.describe LicenseScout::Config do
  describe 'merging config' do
    let(:initial_config) do
      {
        flagged_licenses: [
          'Apache-2.0'
        ],
        fallbacks: {
          habitat: {
            name: 'core/foo',
            license_id: 'Apache-2.0',
            license_content: 'http://example.com'
          }
        }
      }
    end

    let(:supplemental_config) do
      {
        flagged_licenses: [
          'MIT'
        ],
        fallbacks: {
          habitat: [
            {
              name: 'core/foo',
              license_id: 'Apache-2.0',
              license_content: 'http://example.com/apache.license'
            }
          ],
          ruby: [
            {
              name: 'foo',
              license_id: 'MIT',
              license_content: 'http://example.com/mit.license'
            }
          ]
        }
      }
    end

    it 'defers to the most recently merged configuration' do
      LicenseScout::Config.merge!(initial_config)
      LicenseScout::Config.merge!(supplemental_config)

      expect(LicenseScout::Config.flagged_licenses).to eql(['MIT'])
      expect(LicenseScout::Config.fallbacks.habitat).to eql([{
                                                              name: 'core/foo',
                                                              license_id: 'Apache-2.0',
                                                              license_content: 'http://example.com/apache.license'
                                                            }])
      expect(LicenseScout::Config.fallbacks.ruby).to eql([{
                                                           name: 'foo',
                                                           license_id: 'MIT',
                                                           license_content: 'http://example.com/mit.license'
                                                         }])
    end
  end

  describe '.all_directories' do
    let(:initial_config) do
      {
        directories: [
          File.join(SPEC_FIXTURES_DIR, 'deps_gopath')
        ]
      }
    end

    let(:expected_directories) do
      %W[
        #{SPEC_FIXTURES_DIR}/deps_gopath
      ]
    end

    it 'returns the list of directories' do
      LicenseScout::Config.merge!(initial_config)

      expect(LicenseScout::Config.all_directories).to match_array(expected_directories)
    end

    context 'with include-sub-directories' do
      let(:initial_config) do
        {
          include_subdirectories: true,
          directories: [
            File.join(SPEC_FIXTURES_DIR, 'deps_gopath')
          ]
        }
      end

      let(:expected_directories) do
        %W[
          #{SPEC_FIXTURES_DIR}/deps_gopath
          #{SPEC_FIXTURES_DIR}/deps_gopath/src
          #{SPEC_FIXTURES_DIR}/deps_gopath/src/gopkg.in
          #{SPEC_FIXTURES_DIR}/deps_gopath/src/gopkg.in/foo
          #{SPEC_FIXTURES_DIR}/deps_gopath/src/gopkg.in/foo/baz
          #{SPEC_FIXTURES_DIR}/deps_gopath/src/github.com
          #{SPEC_FIXTURES_DIR}/deps_gopath/src/github.com/foo
          #{SPEC_FIXTURES_DIR}/deps_gopath/src/github.com/foo/bar
        ]
      end

      it 'returns all subdirectories as well' do
        LicenseScout::Config.merge!(initial_config)

        expect(LicenseScout::Config.all_directories).to match_array(expected_directories)
      end
    end
  end

  describe '.validate!' do
    context 'when both an allowed and flagged list are specified' do
      before do
        LicenseScout::Config.allowed_licenses = ['Apache-2.0']
        LicenseScout::Config.flagged_licenses = ['MIT']
      end

      it 'raises an error' do
        expect do
          described_class.validate!
        end.to raise_error(LicenseScout::Exceptions::ConfigError,
                           'You may specify a list of licenses to allow or flag. You may not specify both.')
      end
    end

    context 'if one of the directories could not be found' do
      let(:dir) { '/does/not/exist' }

      before do
        LicenseScout::Config.directories = [File.join(SPEC_FIXTURES_DIR, 'berkshelf'), dir]
      end

      it 'raises an error' do
        expect do
          described_class.validate!
        end.to raise_error(LicenseScout::Exceptions::ConfigError,
                           "The '#{dir}' directory could not be found.")
      end
    end
  end
end
