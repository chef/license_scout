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
  module Exceptions
    class Error < RuntimeError; end

    class ProjectDirectoryMissing < Error
      def initialize(project_dir)
        @project_dir = project_dir
      end

      def to_s
        "Could not locate or access the provided project directory '#{@project_dir}'."
      end
    end
  end
end
