#
# Cookbook Name:: omnibus
# HWRP:: ruby_execute
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

require_relative 'language_execute'

class Chef
  class Resource::RubyExecute < Resource::LanguageExecute
    resource_name :ruby_execute

    # Specifies the GEM_HOME.
    # This prevents global gem state by always setting a
    # default not local to global ruby installation cache.
    attribute :gem_home,
              kind_of: String
  end

  class Provider::RubyExecute < Provider::LanguageExecute
    provides :ruby_execute

    #
    # @see Chef::Resource::LanguageExecute#environment
    #
    def environment
      environment = super
      environment['GEM_HOME'] = ::File.expand_path(new_resource.gem_home) unless new_resource.gem_home.nil?

      # Ensure `SSL_CERT_FILE` is set on Windows
      if Chef::Platform.windows?
        candidate_cacert_file = ::File.join(new_resource.prefix, 'ssl', 'certs', 'cacert.pem')
        environment['SSL_CERT_FILE'] = candidate_cacert_file if ::File.exist?(candidate_cacert_file)
      end

      environment
    end
  end
end
