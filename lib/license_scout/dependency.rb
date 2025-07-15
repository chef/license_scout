# frozen_string_literal: true

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

module LicenseScout
  class Dependency
    attr_reader :name, :version, :path, :type, :license

    def initialize(name, version, path, type)
      @name = name
      @version = version
      @path = path
      @type = type

      if path.nil?
        @license = LicenseScout::License.new
      elsif path =~ /^http/ || File.directory?(path)
        @license = LicenseScout::License.new(path)
      else
        raise LicenseScout::Exceptions::MissingSourceDirectory,
              "Could not find the source for '#{name}' in the following directories:\n\t * #{path}"
      end

      fallbacks = LicenseScout::Config.fallbacks.send(type.to_sym).select { |f| f['name'] =~ uid_regexp }
      fallbacks.each do |fallback|
        license.add_license(fallback['license_id'], 'license_scout fallback', fallback['license_file'], force: true)
      end
    end

    # @return [String] The UID for this dependency. Example: bundler (1.16.1)
    def uid
      "#{name} (#{version})"
    end

    # @return [Regexp] The regular expression that can be used to identify this dependency
    def uid_regexp
      Regexp.new("#{Regexp.escape(name)}(\s+\\(#{Regexp.escape(version)}\\))?")
    end

    def exceptions
      @exceptions ||= LicenseScout::Config.exceptions.send(type.to_sym).select { |e| e['name'] =~ uid_regexp }
    end

    # Capture a license that was specified in metadata
    #
    # @param license_id [String] The license as specified in the metadata file
    # @param source [String] Where we found the license info
    # @param contents_url [String] Where we can find the contents of the license
    #
    # @return [void]
    def add_license(license_id, source, contents_url = nil)
      LicenseScout::Log.debug("[#{type}] Adding #{license_id} license for #{name} from #{source}")
      license.add_license(license_id, source, contents_url, {})
    end

    # Determine if this dependency has an exception. Will match an exception for both the name and the name+version
    def has_exception?
      exceptions.any?
    end

    def exception_reason
      exceptions.first['reason'] if has_exception?
    end

    # Be able to sort dependencies by type, then name, then version
    def <=>(other)
      "#{type}#{name}#{version}" <=> "#{other.type}#{other.name}#{other.version}"
    end

    # @return [Boolean] Whether or not this object is equal to another one. Used for Set uniqueness.
    def eql?(other)
      other.is_a?(self.class) && other.hash == hash
    end

    # @return [Integer] A hashcode that can be used to idenitfy this object. Used for Set uniqueness.
    def hash
      [type, name, version].hash
    end
  end
end
