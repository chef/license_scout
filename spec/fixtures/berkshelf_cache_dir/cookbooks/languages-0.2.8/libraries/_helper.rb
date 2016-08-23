#
# Cookbook Name:: languages
# Library:: _helper
#
# Copyright 2015, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'json'

begin
  require 'chef/sugar'
rescue LoadError
  Chef::Log.warn 'chef-sugar gem could not be loaded.'
end

# Various code vendored from omnibus cookbook
module Languages
  module Helper
    include Chef::Sugar::DSL if Chef.const_defined?('Sugar')

    #
    # Performs a `File.join` but ensures all forward slashes are replaced
    # by backward slashes.
    #
    # @return [String]
    #
    def windows_safe_path_join(*args)
      ::File.join(args).gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR)
    end

    #
    # Performs a `File.expand_path` but ensures all forward slashes are
    # replaced by backward slashes.
    #
    # @return [String]
    #
    def windows_safe_path_expand(arg)
      ::File.expand_path(arg).gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR)
    end

    # Execute the given command, removing any Ruby-specific environment
    # variables. This is an "enhanced" version of +Bundler.with_clean_env+,
    # which only removes Bundler-specific values. We need to remove all
    # values, specifically:
    #
    # - _ORIGINAL_GEM_PATH
    # - GEM_PATH
    # - GEM_HOME
    # - GEM_ROOT
    # - BUNDLE_BIN_PATH
    # - BUNDLE_GEMFILE
    # - RUBYLIB
    # - RUBYOPT
    # - RUBY_ENGINE
    # - RUBY_ROOT
    # - RUBY_VERSION
    #
    # The original environment restored at the end of this call.
    #
    # @param [Proc] block
    #   the block to execute with the cleaned environment
    #
    def with_clean_env(&_block)
      original = ENV.to_hash

      ENV.delete('_ORIGINAL_GEM_PATH')
      ENV.delete_if { |k, _| k.start_with?('BUNDLE_') }
      ENV.delete_if { |k, _| k.start_with?('GEM_') }
      ENV.delete_if { |k, _| k.start_with?('RUBY') }

      yield
    ensure
      ENV.replace(original.to_hash)
    end

    #
    # This wrapper around `Chef::Sugar::Shell.installed_at_version?`
    # that returns `false' if Chef Sugar hasn't been loaded yet.
    #
    # @return [String]
    #
    def installed_at_version?(cmd, expected_version, flag = '--version')
      if Chef.const_defined?('Sugar')
        Chef::Sugar::Shell.installed_at_version?(cmd, expected_version, flag)
      else
        false
      end
    end
  end
end

Chef::Recipe.send(:include, Languages::Helper)
Chef::Resource.send(:include, Languages::Helper)
