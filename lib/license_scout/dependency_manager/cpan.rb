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

require "rexml/document"

require "ffi_yajl"
require "psych"
require "mixlib/shellout"

require "license_scout/dependency_manager/base"
require "license_scout/net_fetcher"
require "license_scout/exceptions"
require "license_scout/dependency"

module LicenseScout
  module DependencyManager
    class CPAN < Base

      class CPANDependency

        LICENSE_TYPE_MAP = {
          "perl_5"      => "Perl-5",
          "perl"        => "Perl-5",
          "apache_2_0"  => "Apache-2.0",
          "artistic_2"  => "Artistic-2.0",
          "gpl_3"       => "GPL-3.0",
        }.freeze

        attr_reader :module_name
        attr_reader :dist
        attr_reader :version
        attr_reader :cpanfile

        attr_reader :license_files
        attr_reader :license

        attr_reader :cache_root

        attr_reader :overrides

        def initialize(module_name:, dist:, version:, cpanfile:, cache_root:, overrides:)
          @module_name = module_name
          @dist = dist
          @version = version
          @cpanfile = cpanfile
          @cache_root = cache_root
          @overrides = overrides

          @deps_list = nil

          @license = nil
          @license_files = []
        end

        def desc
          "#{module_name} in #{dist} (#{version}) [#{license}]"
        end

        def to_dep
          Dependency.new(
            # we use dist for the name because there can be multiple modules in
            # a dist, but the dist is the unit of packaging and licensing
            dist,
            version,
            license,
            license_files,
            "perl_cpan"
          )
        end

        def collect_licenses
          ensure_cached
          Dir.mktmpdir do |tmpdir|
            FileUtils.cp(distribution_fullpath, tmpdir)
            Dir.chdir(tmpdir) do
              untar!
              distribution_unpack_fullpath = File.join(tmpdir, distribution_unpack_relpath)
              collect_licenses_in(distribution_unpack_fullpath)
            end
          end
        end

        def ensure_cached
          cache_path = File.join(dist_cache_root, cpanfile)

          # CPAN download URL is like:
          # http://www.cpan.org/authors/id/R/RJ/RJBS/Sub-Install-0.928.tar.gz
          # cpanfile is like:
          # R/RJ/RJBS/Sub-Install-0.928.tar.gz
          unless File.exist?(cache_path)

            url = "http://www.cpan.org/authors/id/#{cpanfile}"
            tmp_path = NetFetcher.cache(url)

            FileUtils.mkdir_p(File.dirname(cache_path))
            FileUtils.cp(tmp_path, cache_path)

          end
        end

        def distribution_filename
          File.basename(cpanfile)
        end

        def distribution_unpack_relpath
          # Most packages have tar.gz extension but some have .tgz like
          # IO-Pager-0.36.tgz
          [".tar.gz", ".tgz"].each do |ext|
            if distribution_filename.end_with?(ext)
              return File.basename(distribution_filename, ext)
            end
          end
        end

        def distribution_fullpath
          File.join(dist_cache_root, cpanfile)
        end

        # Untar the distribution.
        #
        # NOTE: On some platforms, you only get a usable version of tar as
        # `gtar`, and on windows, symlinks break a lot of stuff. We (Chef
        # Software) currently only use perl in server products, which we only
        # build for a handful of Linux distros, so this is sufficient.
        def untar!
          s = Mixlib::ShellOut.new("tar zxf #{distribution_filename}")
          s.run_command
          s.error!
          s.stdout
        end

        def collect_licenses_in(unpack_path)
          collect_license_info_in(unpack_path)
          collect_license_files_info_in(unpack_path)
        end

        def collect_license_info_in(unpack_path)
          # Notice that we use "dist" as the dependency name
          # See #to_dep for details.
          @license = overrides.license_for("perl_cpan", dist, version) || begin
            metadata = if File.exist?(meta_json_in(unpack_path))
                         slurp_meta_json_in(unpack_path)
                       elsif File.exist?(meta_yaml_in(unpack_path))
                         slurp_meta_yaml_in(unpack_path)
                       end

            if metadata && metadata.key?("license")
              given_type = Array(metadata["license"]).reject { |l| l == "unknown" }.first
              normalize_license_type(given_type)
            end
          end
        end

        def collect_license_files_info_in(unpack_path)
          override_license_files = overrides.license_files_for("perl_cpan", dist, version)

          license_files = if override_license_files.empty?
                            find_license_files_in(unpack_path)
                          else
                            override_license_files.resolve_locations(unpack_path)
                          end

          license_files.each do |f|
            @license_files << cache_license_file(f)
          end
        end

        # Copy license file to the cache. We unpack the CPAN dists in a tempdir
        # and throw it away after we've inspected the contents, so we need to
        # put the license file somewhere it can be copied from later.
        def cache_license_file(unpacked_file)
          basename = File.basename(unpacked_file)
          license_cache_path = File.join(license_cache_root, "#{dist}-#{basename}")
          FileUtils.mkdir_p(license_cache_root)
          FileUtils.cp(unpacked_file, license_cache_path)
          # In some cases, the license files get unpacked with 0444
          # permissions which could make a re-run fail on the `cp` step.
          FileUtils.chmod(0644, license_cache_path)
          license_cache_path
        end

        def slurp_meta_yaml_in(unpack_path)
          Psych.safe_load(File.read(meta_yaml_in(unpack_path)))
        end

        def slurp_meta_json_in(unpack_path)
          FFI_Yajl::Parser.parse(File.read(meta_json_in(unpack_path)))
        end

        def license_cache_root
          File.join(cache_root, "cpan-licenses")
        end

        def dist_cache_root
          File.join(cache_root, "cpan-dists")
        end

        def normalize_license_type(given_type)
          LICENSE_TYPE_MAP[given_type] || given_type
        end

        def meta_json_in(unpack_path)
          File.join(unpack_path, "META.json")
        end

        def mymeta_json_in(unpack_path)
          File.join(unpack_path, "MYMETA.json")
        end

        def meta_yaml_in(unpack_path)
          File.join(unpack_path, "META.yml")
        end

        def find_license_files_in(unpack_path)
          Dir["#{unpack_path}/*"].select do |f|
            CPAN::POSSIBLE_LICENSE_FILES.include?(File.basename(f))
          end
        end

      end

      def initialize(*args, &block)
        super
        @dependencies = nil
      end

      def name
        "perl_cpan"
      end

      def dependencies
        return @dependencies if @dependencies
        @dependencies = deps_list.map do |d|
          d.collect_licenses
          d.to_dep
        end
      end

      def deps_list
        return @deps_list if @deps_list

        xml_doc = REXML::Document.new(dependency_graph_xml)

        root = xml_doc.root

        deps = root.get_elements("//dependency")

        @deps_list = []

        deps.each do |dep|
          dep_module_name = dep.get_text("module").to_s
          next if dep_module_name == module_name
          @deps_list << CPANDependency.new(
            module_name: dep_module_name,
            dist: dep.get_text("dist").to_s,
            version: dep.get_text("distversion").to_s,
            cpanfile: dep.get_text("cpanfile").to_s,
            cache_root: options.cpan_cache,
            overrides: options.overrides
          )
        end

        @deps_list
      end

      def dependency_graph_xml
        @dependency_graph_xml ||=
          begin
            dependency_graph_xml_file = NetFetcher.cache(dependency_graph_url)
            raw_xml = File.read(dependency_graph_xml_file)
            FileUtils.rm_f(dependency_graph_xml_file)
            raw_xml
          end
      end

      # NOTE: there's no SSL version available. Take care handling any
      # data/code referenced in responses from this site.
      def dependency_graph_url
        "http://deps.cpantesters.org/?xml=1;module=#{module_name};perl=5.24.0;os=any%20OS;pureperl=0"
      end

      # Infers the module name from the directory name. For Chef Server, the
      # two perl packages we use are:
      # * "App-Sqitch-VERSION" => "App::Sqitch"
      # * "DBD-Pg-VERSION" => "DBD::Pg"
      #
      # NOTE: Distributions may contain multiple modules that would each have
      # their own dependency graphs and it's possible to get a perl project
      # that doesn't obey this convention (e.g., if you git clone it). But this
      # meets our immediate needs.
      def module_name
        File.basename(project_dir).split("-")[0...-1].join("::")
      end

      # NOTE: it's possible that projects won't have a META.yml, but the two
      # that we care about for Chef Server do have one. As of 2015, 84% of perl
      # distribution packages have one: http://neilb.org/2015/10/18/spotters-guide.html
      def detected?
        File.exist?(meta_yml_path)
      end

      def meta_yml_path
        File.join(project_dir, "META.yml")
      end

    end
  end
end
