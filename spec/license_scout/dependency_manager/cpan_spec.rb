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

require "tmpdir"
require "fileutils"

require "license_scout/dependency_manager/cpan"
require "license_scout/overrides"
require "license_scout/options"

RSpec.describe(LicenseScout::DependencyManager::CPAN) do

  subject(:cpan) do
    described_class.new(project_dir, LicenseScout::Options.new(
      overrides: overrides,
      cpan_cache: cpan_cache
    ))
  end

  let(:tmpdir) { Dir.mktmpdir }

  let(:cpan_cache) { File.join(tmpdir, "cpan_cache") }

  let(:project_dir) { File.join(tmpdir, "App-Example-1.0.0") }

  let(:overrides) { LicenseScout::Overrides.new }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  it "has a name" do
    expect(cpan.name).to eq("perl_cpan")
  end

  it "has a project directory" do
    expect(cpan.project_dir).to eq(project_dir)
  end

  it "infers the module name from the directory" do
    expect(cpan.module_name).to eq("App::Example")
  end

  describe "when provided a perl project" do
    before do
      Dir.mkdir(project_dir)
      # NOTE: it's possible that projects won't have a META.yml, but the two
      # that we care about for Chef Server do have one. As of 2015, 84% of perl
      # distribution packages have one: http://neilb.org/2015/10/18/spotters-guide.html
      FileUtils.touch(File.join(project_dir, "META.yml"))
    end

    it "detects a perl project correctly" do
      expect(cpan.detected?).to eq(true)
    end
  end

  describe "when provided a non-perl project" do
    before do
      Dir.mkdir(project_dir)
    end

    it "does not detect the project" do
      expect(cpan.detected?).to eq(false)
    end
  end

  describe "when given a real cpan project" do

    let(:project_dir) { File.join(tmpdir, "App-Sqitch-0.973") }

    let(:deps_xml_file_fixture) { File.join(SPEC_FIXTURES_DIR, "cpan", "app_sqitch_deps.xml") }

    let(:deps_xml_file) do
      path = File.join(tmpdir, "app_sqitch_deps.xml")
      FileUtils.cp(deps_xml_file_fixture, path)
      path
    end

    let(:deps_url) do
      "http://deps.cpantesters.org/?xml=1;module=App::Sqitch;perl=5.24.0;os=any%20OS;pureperl=0"
    end

    let(:dep_module_names) do
      %w{
        Scalar::Util
        IO::File
        ExtUtils::MakeMaker
        Exporter
        Carp
        Pod::Escapes
        Pod::Usage
        Encode
        Moo::Role
        Role::Tiny
        Try::Tiny
        Module::Metadata
        constant
        Module::Runtime
        ExtUtils::Install
        File::Path
        version
        TAP::Harness
        Text::ParseWords
        Devel::GlobalDestruction
        Sub::Exporter::Progressive
        Test::Deep
        XSLoader
        IPC::Cmd
        Config::GitLike
        Test::Exception
        MooX::Types::MooseLike
        Time::HiRes
        parent
        MIME::Base64
        namespace::autoclean
        Sub::Identify
        B::Hooks::EndOfScope
        namespace::clean
        Test::Warnings
        Test::Dir
        Digest::SHA
        Test::utf8
        Test::File::Contents
        Digest::MD5
        Encode::Locale
        Hash::Merge
        Clone
        URI::db
        URI::Nested
        File::Spec
        base
        Getopt::Long
        ExtUtils::ParseXS
        Data::Dumper
        Pod::Find
        String::ShellQuote
        Test
        IO::Pager
        Storable
        Algorithm::Diff
        Capture::Tiny
        warnings
        Test::More
        File::Temp
        lib
        Type::Utils
        Exporter::Tiny
        Template::Tiny
        Sub::Exporter
        Params::Util
        ExtUtils::CBuilder
        Data::OptList
        Sub::Install
        if
        StackTrace::Auto
        Test::Fatal
        Module::Build
        CPAN::Meta
        Perl::OSType
        ExtUtils::Manifest
        Parse::CPAN::Meta
        Text::Abbrev
        Pod::Man
        CPAN::Meta::YAML
        Class::Method::Modifiers
        Test::Requires
        Devel::StackTrace
        List::MoreUtils
        DBI
        File::HomeDir
        File::Which
        Sub::Uplevel
        PerlIO::utf8_strict
        IPC::Run3
        Path::Class
        URI
        Module::Implementation
        Package::Stash
        Dist::CheckConflicts
        Env
        DateTime
        CPAN::Meta::Check
        CPAN::Meta::Requirements
        DateTime::Locale
        Params::Validate
        DateTime::TimeZone
        Test::MockModule
        SUPER
        Test::NoWarnings
        Time::Local
        Term::ANSIColor
        Test::File
        IPC::System::Simple
        Text::Diff
        String::Formatter
        Locale::Messages
      }
    end

    before do
      Dir.mkdir(project_dir)
      FileUtils.touch(File.join(project_dir, "META.yml"))
      expect(LicenseScout::NetFetcher).to receive(:cache).
        with(deps_url).
        and_return(deps_xml_file)
    end

    it "fetches dependency info from cpantesters.org" do
      expect(cpan.dependency_graph_xml).to eq(File.read(deps_xml_file_fixture))
    end

    it "ensures dependency info is re-fetched on every run" do
      cpan.dependency_graph_xml
      expect(File).to_not exist(deps_xml_file)
    end

    it "fetches a full dependency list" do
      expect(cpan.deps_list.map(&:module_name)).to match_array(dep_module_names)
    end

    describe "fetching cpan distributions and collecting licenses" do

      def cpan_url(cpan_path)
        "http://www.cpan.org/authors/id/#{cpan_path}"
      end

      def fixture_pkg(pkg_name)
        File.join(SPEC_FIXTURES_DIR, "cpan", "dists", pkg_name)
      end

      before do

        cpan.deps_list.each do |cpan_dep|
          case cpan_dep.module_name

          # Has license file and type is in metadata:
          when "Capture::Tiny"
            expect(LicenseScout::NetFetcher).to receive(:cache).
              with(cpan_url("D/DA/DAGOLDEN/Capture-Tiny-0.44.tar.gz")).
              and_return(fixture_pkg("Capture-Tiny-0.44.tar.gz"))

          # Has license file, type is not in metadata:
          when "Locale::Messages"
            expect(LicenseScout::NetFetcher).to receive(:cache).
              with(cpan_url("G/GU/GUIDO/libintl-perl-1.26.tar.gz")).
              and_return(fixture_pkg("libintl-perl-1.26.tar.gz"))

          # Has type in metadata, but no file:
          when "Scalar::Util"
            expect(LicenseScout::NetFetcher).to receive(:cache).
              with(cpan_url("P/PE/PEVANS/Scalar-List-Utils-1.45.tar.gz")).
              and_return(fixture_pkg("Scalar-List-Utils-1.45.tar.gz"))

          # No license info at all:
          when "File::Spec"
            expect(LicenseScout::NetFetcher).to receive(:cache).
              with(cpan_url("R/RJ/RJBS/PathTools-3.62.tar.gz")).
              and_return(fixture_pkg("PathTools-3.62.tar.gz"))

          else
            expect(cpan_dep).to receive(:collect_licenses)
          end

        end
      end

      it "detects the licenses of the transitive dependencies correctly" do
        expect(cpan.dependencies.size).to eq(dep_module_names.size)

        capture_tiny = cpan.dependencies.find { |d| d.name == "Capture-Tiny" }
        expect(capture_tiny.license).to eq("Apache-2.0")
        expect(capture_tiny.license_files.size).to eq(1)
        expect(File).to exist(capture_tiny.license_files.first)
        expected_path = File.join(cpan_cache, "cpan-licenses", "Capture-Tiny-LICENSE")
        expect(capture_tiny.license_files.first).to eq(expected_path)

        libintl = cpan.dependencies.find { |d| d.name == "libintl-perl" }
        expect(libintl.license).to be_nil
        expect(libintl.license_files.size).to eq(1)
        expected_path = File.join(cpan_cache, "cpan-licenses", "libintl-perl-COPYING")
        expect(libintl.license_files.first).to eq(expected_path)

        scalar_util = cpan.dependencies.find { |d| d.name == "Scalar-List-Utils" }
        expect(scalar_util.license).to eq("Perl-5")
        expect(scalar_util.license_files.size).to eq(0)

        path_tools = cpan.dependencies.find { |d| d.name == "PathTools" }
        expect(path_tools.license).to be_nil
        expect(path_tools.license_files.size).to eq(0)
      end
    end
  end
end
