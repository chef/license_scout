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
  Dependency = Struct.new(:name, :version, :license, :license_files, :dep_mgr_name) do

    def eql?(other)
      other.kind_of?(self.class) && other.hash == hash
    end

    # hash code for when Dependency is used as a key in a Hash or member of a
    # Set. The implementation is somewhat naive, but will work fine if you
    # don't go too crazy mixing different types.
    def hash
      [dep_mgr_name, name, version, license].hash
    end

  end
end
