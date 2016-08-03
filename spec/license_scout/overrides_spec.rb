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

require "license_scout/overrides"

RSpec.describe(LicenseScout::Overrides) do

  subject(:overrides) do
    LicenseScout::Overrides.new() do
      override_license "test_dep_manager", "example1" do |version|
        {
          license: "BSD",
          license_files: [ "BSD-LICENSE" ],
        }
      end
    end
  end

  describe "when an override exists for a dependency" do
    it "finds the license for a given dependency manager, dep name, and dep version" do
      expect(overrides.license_for("test_dep_manager", "example1", "1.0.0")).to eq("BSD")
    end

    it "finds the license files for a given dep manager name, dep name and dep version" do
      expect(overrides.license_files_for("test_dep_manager", "example1", "1.0.0")).to eq(["BSD-LICENSE"])
    end
  end

  describe "when an override doesn't exist for a dependency" do
    it "returns nil for the dependency's license" do
      expect(overrides.license_for("test_dep_manager", "example99", "1.0.0")).to eq(nil)
    end

    it "return an empty array for the dependency's license files" do
      expect(overrides.license_files_for("test_dep_manager", "example99", "1.0.0")).to eq([])
    end
  end

  describe "when no overrides exist for the given dependency manager" do
    it "returns nil for the dependency's license" do
      expect(overrides.license_for("nope_dep_manager", "example99", "1.0.0")).to eq(nil)
    end

    it "return an empty array for the dependency's license files" do
      expect(overrides.license_files_for("nope_dep_manager", "example99", "1.0.0")).to eq([])
    end
  end

end
