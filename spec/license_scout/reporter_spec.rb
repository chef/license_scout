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

require "license_scout/reporter"

RSpec.describe(LicenseScout::Reporter) do
  subject(:reporter) do
    described_class.new(output_directory)
  end

  describe "with a non-existing output directory" do
    let(:output_directory) { File.join(SPEC_FIXTURES_DIR, "not_exists") }

    it "raises reporting error" do
      expect { reporter.report }.to raise_error(LicenseScout::Exceptions::InvalidOutputReport, /does not exist/)
    end
  end

  describe "with an invalid output directory" do
    describe "no manifest" do

      let(:output_directory) { File.join(SPEC_FIXTURES_DIR, "output_no_manifest") }

      it "raises reporting error" do
        expect { reporter.report }.to raise_error(LicenseScout::Exceptions::InvalidOutputReport, /Can not find a dependency license manifest/)
      end
    end

    describe "multiple manifests" do
      let(:output_directory) { File.join(SPEC_FIXTURES_DIR, "output_multiple_manifests") }

      it "raises reporting error" do
        expect { reporter.report }.to raise_error(LicenseScout::Exceptions::InvalidOutputReport, /Found multiple manifests/)
      end
    end

  end

  describe "with a licensing report without errors" do
    let(:output_directory) { File.join(SPEC_FIXTURES_DIR, "output_no_errors") }

    it "reports no issues" do
      expected = [">> Found 3 dependencies for ruby_bundler. 3 OK, 0 with problems"]
      expect(reporter.report).to eq(expected)
    end
  end

  describe "with a licensing file with metadata errors" do
    let(:output_directory) { File.join(SPEC_FIXTURES_DIR, "output_metadata_errors") }
    let(:expected_errors) do
      [
        "There is a dependency with a missing name in 'ruby_bundler'.",
        "Dependency 'appbundler' under 'ruby_bundler' is missing version information.",
        "Dependency 'bundler' version '1.12.5' under 'ruby_bundler' is missing license information.",
        "Dependency 'pry' version '0.12.2' under 'ruby_bundler' is missing license files information.",
      ]
    end

    let(:expected_summary) do
      ">> Found 4 dependencies for ruby_bundler. 0 OK, 4 with problems"
    end

    let(:expected_report) do
      expected_errors + [ expected_summary ]
    end

    it "reports the errors" do
      report = reporter.report

      expect(report.length).to eq(expected_report.length)
      expected_errors.each do |error|
        expect(report).to include(error)
      end
      expect(report.last).to eq(expected_summary)
    end
  end

  describe "with a licensing file with missing license files" do
    let(:output_directory) { File.join(SPEC_FIXTURES_DIR, "output_missing_files") }
    let(:expected_errors) do
      [
        "License file 'ruby_bundler-mixlib-cli-1.7.0-LICENSE' for the dependency 'mixlib-cli' version '1.7.0' under 'ruby_bundler' is missing.",
        "License file 'ruby_bundler-appbundler-0.9.0-LICENSE.txt' for the dependency 'appbundler' version '0.9.0' under 'ruby_bundler' is missing.",
      ]
    end

    let(:expected_summary) do
      ">> Found 3 dependencies for ruby_bundler. 1 OK, 2 with problems"
    end

    let(:expected_report) do
      expected_errors + [ expected_summary ]
    end

    it "reports the errors" do
      report = reporter.report

      expect(report.length).to eq(expected_report.length)
      expected_errors.each do |error|
        expect(report).to include(error)
      end
      expect(report.last).to eq(expected_summary)
    end
  end

end
