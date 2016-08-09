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

require "license_scout/license_file_analyzer"

RSpec.describe(LicenseScout::LicenseFileAnalyzer) do

  def license_file(basename)
    IO.read(File.join(SPEC_FIXTURES_DIR, "license_analyzer_licenses", basename))
  end

  it "detects an unmodified Apache 2.0 License" do
    expect(described_class.find_by_text(license_file("ej-apache2-license")).short_name).to eq("Apache2")
  end

  it "detects the short version of the Apache 2.o License" do
    expect(described_class.find_by_text(license_file("hoax-apache2-short")).short_name).to eq("Apache2")
  end

  it "detects a MIT license with copyright holder filled in" do
    expect(described_class.find_by_text(license_file("eper-mit")).short_name).to eq("MIT")
  end

  it "detects a BSD 3 clause license with copyright holder filled in and possessive changed" do
    # This is the line that is tricky to match:
    # > Neither the name of Will Glozer nor the names of his contributors may be
    # > used to endorse or promote products derived from this software without
    # > specific prior written permission.
    expect(described_class.find_by_text(license_file("epgsql-bsd-3-clause")).short_name).to eq("BSD-3-Clause")
  end

  it "detects a BSD 3 clause license with the 3 clauses as paragraphs w/o bullet points" do
    expect(described_class.find_by_text(license_file("recon-bsd-3-clause-alt-format")).short_name).to eq("BSD-3-Clause")
  end

  it "detects a BSD 2 clause license which is the 3 clause version with the third clause deleted" do
    expect(described_class.find_by_text(license_file("esaml-bsd-2-clause")).short_name).to eq("BSD-2-Clause")
  end

  it "detects gen_smtp's 2 clause BSD" do
    expect(described_class.find_by_text(license_file("gen_smtp-BSD-2-clause")).short_name).to eq("BSD-2-Clause")
  end
end
