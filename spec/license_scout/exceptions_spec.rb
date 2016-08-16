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

require "license_scout/exceptions"

RSpec.describe(LicenseScout::Exceptions) do

  it "ProjectDirectoryMissing is raiseable" do
    expect(LicenseScout::Exceptions::ProjectDirectoryMissing.new("/path/to/project").to_s).to be_a(String)
  end

  it "UnsupportedProjectType is raiseable" do
    expect(LicenseScout::Exceptions::UnsupportedProjectType.new("/path/to/project").to_s).to be_a(String)
  end

  it "UnsupportedProjectType is raiseable" do
    expect(LicenseScout::Exceptions::UnsupportedProjectType.new("/path/to/project").to_s).to be_a(String)
  end

  it "DependencyManagerNotRun is raiseable" do
    expect(LicenseScout::Exceptions::DependencyManagerNotRun.new("/path/to/project", "dep_mgr_name").to_s).to be_a(String)
  end

  it "NetworkError is raiseable" do
    expect(LicenseScout::Exceptions::NetworkError.new("http://problematic.url.com/", StandardError.new).to_s).to be_a(String)
  end

end
