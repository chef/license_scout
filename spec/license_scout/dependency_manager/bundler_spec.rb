#
# Copyright:: Copyright 2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

RSpec.describe LicenseScout::DependencyManager::Bundler do

  let(:subject) { described_class.new(directory) }
  let(:directory) { "/some/random/directory" }

  let(:gemfile_path) { File.join(directory, "Gemfile") }
  let(:gemfile_lock_path) { File.join(directory, "Gemfile.lock") }

  describe ".new" do
    it "creates new instance of a dependency manager" do
      expect(subject.directory).to eql(directory)
    end
  end

  describe "#name" do
    it "equals 'ruby_bundler'" do
      expect(subject.name).to eql("ruby_bundler")
    end
  end

  describe "#type" do
    it "equals 'ruby'" do
      expect(subject.type).to eql("ruby")
    end
  end

  describe "#signature" do
    it "equals 'Gemfile and Gemfile.lock files'" do
      expect(subject.signature).to eql("Gemfile and Gemfile.lock files")
    end
  end

  describe "#install_command" do
    it "returns 'bundle install'" do
      expect(subject.install_command).to eql("bundle install")
    end
  end

  describe "#detected?" do
    let(:gemfile_exists) { true }
    let(:gemfile_lock_exists) { true }

    before do
      expect(File).to receive(:exist?).with(gemfile_path).and_return(gemfile_exists)
      expect(File).to receive(:exist?).with(gemfile_lock_path).and_return(gemfile_lock_exists)
    end

    context "when Gemfile and Gemfile.lock exist" do
      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when either Gemfile or Gemfile.lock is missing" do
      let(:gemfile_exists) { true }
      let(:gemfile_lock_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end
  end

  describe "#dependencies", :vcr do
    let(:tmpdir) { Dir.mktmpdir }
    let(:directory) { File.join(tmpdir, "bundler_project") }

    let(:bundler_project_fixture) { File.join(SPEC_FIXTURES_DIR, "bundler_top_level_project") }
    let(:bundler_gems_fixture) { File.join(SPEC_FIXTURES_DIR, "bundler_gems_dir") }
    let(:bundler_gems_dir) { File.expand_path("vendor/bundle/ruby/#{Gem.ruby_api_version}/", directory) }

    before do
      FileUtils.cp_r(bundler_project_fixture, directory)
      FileUtils.mkdir_p(bundler_gems_dir)
      FileUtils.cp_r("#{bundler_gems_fixture}/.", bundler_gems_dir)
    end

    # tmpdir when running as non-root on OS X is a symlink which we have to resolve
    def gem_rel_path(path)
      Pathname(File.join(bundler_gems_dir, path)).realpath.to_s
    end

    it "returns an array of Dependencies found in the directory" do
      dependencies = subject.dependencies

      # Make sure we have the right count
      expect(dependencies.length).to eq(10)

      # We check the bundler intentionally because we are handling it differently
      bundler_info = dependencies.find { |d| d.name == "bundler" }
      expect(bundler_info.license.records.length).to eq(1)
      expect(bundler_info.license.records.first.id).to eq("MIT")
      expect(bundler_info.license.records.first.source).to eql("LICENSE.md")

      # We check mixlib-install an example out of 10 dependencies.
      mixlib_install_info = dependencies.find { |d| d.name == "mixlib-install" }
      expect(mixlib_install_info.version).to eq("1.1.0")
      expect(mixlib_install_info.license.records.length).to eq(2)
      expect(mixlib_install_info.license.records.first.id).to eq("Apache-2.0")
      expect(mixlib_install_info.license.records.first.source).to eq("LICENSE")
      expect(mixlib_install_info.license.records[1].id).to eql("Apache-2.0")
      expect(mixlib_install_info.license.records[1].source).to eql("https://rubygems.org/gems/mixlib-install/versions/1.1.0")
    end
  end
end
