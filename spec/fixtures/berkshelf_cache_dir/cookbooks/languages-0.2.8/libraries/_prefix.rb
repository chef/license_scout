#
# Cookbook Name:: languages
# Library:: _prefix
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

module Languages
  module Prefix
    #
    # /opt/languages
    # C:\languages
    #
    def default_prefix_base
      if Chef::Platform.windows?
        ::File.join(ENV['SYSTEMDRIVE'], 'languages')
      else
        '/opt/languages'
      end
    end

    #
    # /opt/languages/<LANGUAGE>/<VERSION>
    # C:\languages\<LANGUAGE>\<VERSION>
    #
    def default_prefix(version)
      # Infer the language from the class name
      #
      # Takes something like `Chef::Resource::RubyInstall`
      # and returns `Ruby`
      #
      language = self.class.to_s.split('::').last.split(/(?=[A-Z])/).first
      ::File.join(default_prefix_base, language.downcase, version)
    end
  end
end
