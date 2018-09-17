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

require "licensee"
require "license_scout/dependency"
require "license_scout/exceptions"

require "bundler"
require "ffi_yajl"
require "net/http"
require "mixlib/shellout"
require "pathname"
require "psych"
require "set"
require "toml-rb"
require "yaml"

module LicenseScout
  # The DependencyManager module (or more accurately, implementations of it) are responsible for recognizing
  # when a dependency manager such as Bundler, Rebar, Berkshelf, etc is managing dependencies for source code
  # in the given directory.
  module DependencyManager
    class Base

      attr_reader :directory

      # @param directory [String] The fully-qualified path to the directory to be inspected
      def initialize(directory)
        @directory = directory
        @deps = nil
      end

      # The unique name of this Dependency Manager. In general, the name should follow the `<TYPE>_<NAME` pattern where:
      #   * <TYPE> is the value of DependencyManager#type
      #   * <NAME> is the name of the dependency manager.
      #
      # @example Go's various package managers
      #   Name        Reference
      #   --------    -----------------------------------------------
      #   go_dep      [`godep`](https://github.com/tools/godep)
      #   go_godep    [`dep`](https://github.com/golang/dep)
      #   go_glide    [`glide`](https://github.com/Masterminds/glide)
      #
      # @return [String]
      def name
        raise LicenseScout::Exceptions::Error.new("All DependencyManagers must have a `#name` method")
      end

      # The "type" of dependencies this manager manages. This can be the language, tool, etc.
      #
      # @return [String]
      def type
        raise LicenseScout::Exceptions::Error.new("All DependencyManagers must have a `#type` method")
      end

      # A human-readable description of the files/folders that indicate this dependency manager is in use.
      #
      # @return [String]
      def signature
        raise LicenseScout::Exceptions::Error.new("All DependencyManagers must have a `#signature` method")
      end

      # Whether or not we were able to detect that this dependency manager is currently in use in our directory
      #
      # @return [Boolean]
      def detected?
        raise LicenseScout::Exceptions::Error.new("All DependencyManagers must have a `#detected?` method")
      end

      # The command to run to install dependency if one or more is missing
      #
      # @return [String]
      def install_command
        raise LicenseScout::Exceptions::Error.new("All DependencyManagers must have a `#install_command` method")
      end

      # Implementation's of this method in sub-classes are the methods that are responsible for all
      # the heavy-lifting when it comes to determining the dependencies (and their licenses).
      # They should return an array of `LicenseScout::Dependency`.
      #
      # @return [Array<LicenseScout::Dependency>]
      def dependencies
        []
      end

      private

      # A helper that allows you to quickly create a new Dependency (with the type)
      #
      # @param name [String] The name of the dependency
      # @param version [String] The version of the dependency
      # @param path [String] The path to the dependency on the local system
      #
      # @return [LicenseScout::Dependency]
      # @api private
      def new_dependency(name, version, path)
        LicenseScout::Log.debug("[#{type}] Found #{name} #{version}#{" #{path}" unless path.nil?}")
        Dependency.new(name, version, path, type)
      end
    end
  end
end
