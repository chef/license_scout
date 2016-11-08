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

require "license_scout/net_fetcher"

require "pathname"

module LicenseScout
  class Overrides

    class OverrideLicenseSet

      attr_reader :license_locations

      def initialize(license_locations)
        @license_locations = license_locations || []
      end

      def empty?
        license_locations.empty?
      end

      def resolve_locations(dependency_root_dir)
        license_locations.map do |license_location|
          if NetFetcher.remote?(license_location)
            NetFetcher.cache(license_location)
          else
            normalize_and_verify_path(license_location, dependency_root_dir)
          end
        end
      end

      def normalize_and_verify_path(license_location, dependency_root_dir)
        full_path = File.expand_path(license_location, dependency_root_dir)
        if File.exists?(full_path)
          full_path
        else
          raise Exceptions::InvalidOverride, "Provided license file path '#{license_location}' can not be found under detected dependency path '#{dependency_root_dir}'."
        end
      end

    end

    attr_reader :override_rules

    def initialize(exclude_default: false, &rules)
      @override_rules = {}
      instance_eval(&rules) if block_given?

      default_overrides unless exclude_default
    end

    def override_license(dependency_manager, dependency_name, &rule)
      override_rules[dependency_manager] ||= {}
      override_rules[dependency_manager][dependency_name] = rule
    end

    def license_for(dependency_manager, dependency_name, dependency_version)
      license_data = license_data_for(dependency_manager, dependency_name, dependency_version)
      license_data && license_data[:license]
    end

    def license_files_for(dependency_manager, dependency_name, dependency_version)
      license_data = license_data_for(dependency_manager, dependency_name, dependency_version)
      OverrideLicenseSet.new(license_data && license_data[:license_files])
    end

    def have_override_for?(dependency_manager, dependency_name, dependency_version)
      override_rules.key?(dependency_manager) && override_rules[dependency_manager].key?(dependency_name)
    end

    private

    def license_data_for(dependency_manager, dependency_name, dependency_version)
      return nil unless have_override_for?(dependency_manager, dependency_name, dependency_version)
      override_rules[dependency_manager][dependency_name].call(dependency_version)
    end

    def canonical(shortname)
      File.expand_path("../canonical_licenses/#{shortname}.txt", __FILE__)
    end

    def default_overrides
      # Default overrides for ruby_bundler dependency manager.
      [
        ["debug_inspector", "MIT", ["README.md"]],
        ["inifile", "MIT", ["README.md"]],
        ["syslog-logger", "MIT", ["README.rdoc"]],
        ["httpclient", "Ruby", ["README.md"]],
        ["little-plugger", "MIT", ["README.rdoc"]],
        ["logging", "MIT", ["README.md"]],
        ["coderay", nil, ["README_INDEX.rdoc"]],
        ["multipart-post", "MIT", ["README.md"]],
        ["erubis", "MIT", nil],
        ["binding_of_caller", "MIT", nil],
        ["method_source", "MIT", nil],
        ["pry-remote", "MIT", nil],
        ["pry-stack_explorer", "MIT", nil],
        ["plist", "MIT", nil],
        ["proxifier", "MIT", nil],
        ["mixlib-shellout", "Apache-2.0", nil],
        ["mixlib-log", "Apache-2.0", nil],
        ["uuidtools", "Apache-2.0", nil],
        ["cheffish", "Apache-2.0", nil],
        ["chef-provisioning", "Apache-2.0", nil],
        ["chef-provisioning-aws", "Apache-2.0", nil],
        ["chef-rewind", "MIT", nil],
        ["ubuntu_ami", "Apache-2.0", nil],
        ["net-telnet", "Ruby", nil],
        ["netrc", "MIT", nil],
        ["oc-chef-pedant", "Apache-2.0", nil],
        ["rake", "MIT", nil],
        ["rspec", "MIT", nil],
        ["yajl-ruby", "MIT", nil],
        ["bunny", "MIT", nil],
        ["em-http-request", "MIT", nil],
        ["sequel", "MIT", nil],
        ["reel", "MIT", nil],
        ["spork", "MIT", nil],
        ["rack-test", "MIT", nil],
        ["rework", "MIT", ["Readme.md"]],
        ["rework-visit", "MIT", ["Readme.md"]],
        ["source-map-resolve", "MIT", ["LICENSE"]],
        ["source-map-url", "MIT", ["LICENSE"]],
        ["moneta", "MIT", nil],
        ["mixlib-authentication", "Apache-2.0", nil],
        ["mixlib-cli", "Apache-2.0", nil],
        ["ohai", "Apache-2.0", nil],
        ["chef", "Apache-2.0", nil],
        ["ipaddress", "MIT", nil],
        ["systemu", "BSD-2-Clause", nil],
        ["pry", "MIT", nil],
        ["puma", "BSD-3-Clause", nil],
        ["rb-inotify", "MIT", nil],
        ["chef-web-core", "Apache-2.0", nil],
        ["knife-opc", "Apache-2.0", nil],
        ["highline", "Ruby", ["LICENSE"]],
        ["unicorn", "Ruby", ["LICENSE"]],
        ["winrm-fs", "Apache-2.0", nil],
        ["codecov", "MIT", ["https://raw.githubusercontent.com/codecov/codecov-ruby/master/LICENSE.txt"]],
        ["net-http-persistent", "MIT", ["README.rdoc"]],
        ["net-http-pipeline", "MIT", ["README.txt"]],
        ["websocket", "MIT", ["README.md"]],
        # Overrides that require file fetching from internet
        ["sfl", "Ruby", ["https://raw.githubusercontent.com/ujihisa/spawn-for-legacy/master/LICENCE.md"]],
        ["json_pure", nil, ["https://raw.githubusercontent.com/flori/json/master/README.md"]],
        ["aws-sdk-core", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
        ["aws-sdk-resources", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
        ["aws-sdk", nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/README.md"]],
        ["fuzzyurl", nil, ["https://raw.githubusercontent.com/gamache/fuzzyurl/master/LICENSE.txt"]],
        ["jwt", nil, ["https://github.com/jwt/ruby-jwt/blob/master/LICENSE"]],
        ["win32-process", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-api", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-dir", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-ipc", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-event", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-eventlog", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-mmap", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-mutex", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["win32-service", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["windows-api", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["rdoc", "Ruby", ["https://raw.githubusercontent.com/rdoc/rdoc/master/LICENSE.rdoc"]],
        ["rest-client", "MIT", ["https://raw.githubusercontent.com/rest-client/rest-client/master/LICENSE"]],
        ["rspec-rerun", nil, ["https://raw.githubusercontent.com/dblock/rspec-rerun/master/LICENSE.md"]],
        ["amqp", "Ruby", ["https://raw.githubusercontent.com/ruby-amqp/amqp/master/README.md"]],
        ["fast_xs", "MIT", ["https://raw.githubusercontent.com/brianmario/fast_xs/master/LICENSE"]],
        ["word-salad", "MIT", ["https://raw.githubusercontent.com/alexvollmer/word_salad/master/README.txt"]],
        ["minitest", nil, ["https://raw.githubusercontent.com/seattlerb/minitest/master/README.rdoc"]],
        ["cucumber-wire", nil, ["https://raw.githubusercontent.com/cucumber/cucumber-ruby-wire/master/LICENSE"]],
        ["minitar", "Ruby", ["https://raw.githubusercontent.com/atoulme/minitar/master/README"]],
        ["enumerable-lazy", "MIT", ["https://raw.githubusercontent.com/yhara/enumerable-lazy/master/README.md"]],
        ["rack-accept", "MIT", ["https://raw.githubusercontent.com/mjackson/rack-accept/master/README.md"]],
        ["net-http-spy", "Public-Domain", ["https://raw.githubusercontent.com/martinbtt/net-http-spy/master/readme.markdown"]],
        ["http_parser.rb", nil, ["https://raw.githubusercontent.com/tmm1/http_parser.rb/master/LICENSE-MIT"]],
        ["websocket-extensions", nil, ["https://raw.githubusercontent.com/faye/websocket-extensions-ruby/master/LICENSE.md"]],
        ["websocket-driver", nil, ["https://raw.githubusercontent.com/faye/websocket-driver-ruby/master/LICENSE.md"]],
        ["dep_selector", nil, ["https://raw.githubusercontent.com/chef/dep-selector/master/LICENSE"]],
        ["overcommit", nil, ["https://raw.githubusercontent.com/brigade/overcommit/master/MIT-LICENSE"]],
        ["github_changelog_generator", nil, ["https://raw.githubusercontent.com/skywinder/github-changelog-generator/master/LICENSE"]],
        ["pbkdf2", "MIT", ["https://raw.githubusercontent.com/emerose/pbkdf2-ruby/master/LICENSE.TXT"]],
        ["rails-deprecated_sanitizer", nil, ["https://raw.githubusercontent.com/rails/rails-deprecated_sanitizer/master/LICENSE"]],
        ["rails-html-sanitizer", nil, ["https://raw.githubusercontent.com/rails/rails-html-sanitizer/master/MIT-LICENSE"]],
        ["compass", "MIT", ["https://raw.githubusercontent.com/Compass/compass/stable/LICENSE.markdown"]],
        ["railties", nil, ["https://raw.githubusercontent.com/rails/rails/master/railties/MIT-LICENSE"]],
        ["coffee-script-source", nil, ["https://raw.githubusercontent.com/jessedoyle/coffee-script-source/master/LICENSE"]],
        ["omniauth-chef", nil, ["https://raw.githubusercontent.com/chef/omniauth-chef/master/README.md"]],
        ["rails", nil, ["https://raw.githubusercontent.com/rails/rails/master/README.md"]],
        ["unicorn-rails", "MIT", ["https://raw.githubusercontent.com/samuelkadolph/unicorn-rails/master/LICENSE"]],
        ["hoe", "MIT", ["https://raw.githubusercontent.com/seattlerb/hoe/master/README.rdoc"]],
        ["rubyzip", nil, ["https://raw.githubusercontent.com/rubyzip/rubyzip/master/README.md"]],
        ["url", "MIT", ["https://raw.githubusercontent.com/tal/URL/master/LICENSE"]],
        ["mocha", "MIT", ["https://raw.githubusercontent.com/freerange/mocha/master/MIT-LICENSE.md"]],
        ["sslshake", "MPL-2.0", ["https://raw.githubusercontent.com/arlimus/sslshake/master/README.md"]],
        ["inspec-msccm", nil, ["https://www.chef.io/online-master-agreement/"]],
        ["inspec-scap", nil, ["https://www.chef.io/online-master-agreement/"]],
      ].each do |override_data|
        override_license "ruby_bundler", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end

      # chef_berkshelf
      [
        ["apt", nil, ["https://raw.githubusercontent.com/chef-cookbooks/apt/master/LICENSE"]],
        ["chef-ha-drbd", nil, ["https://raw.githubusercontent.com/chef/chef-server/master/LICENSE"]],
        ["private-chef", nil, ["https://raw.githubusercontent.com/chef/chef-server/master/LICENSE"]],
        ["chef-sugar", nil, ["https://raw.githubusercontent.com/sethvargo/chef-sugar/master/LICENSE"]],
        ["openssl", nil, ["https://raw.githubusercontent.com/chef-cookbooks/openssl/master/LICENSE"]],
        ["runit", nil, ["https://raw.githubusercontent.com/chef-cookbooks/runit/master/LICENSE"]],
        ["yum", nil, ["https://raw.githubusercontent.com/chef-cookbooks/yum/master/LICENSE"]],
      ].each do |override_data|
        override_license "chef_berkshelf", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end

      # Most of the overrides for perl_cpan are pointing to the README files
      # inside the modules we download to inspect for licensing information.
      [
        ["Scalar-List-Utils", nil, ["README"]],
        ["perl", nil, ["README"]],
        ["IO", nil, ["README"]],
        ["ExtUtils-MakeMaker", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["PathTools", "Perl-5", ["lib/File/Spec.pm"]],
        ["Exporter", nil, ["README"]],
        ["Carp", nil, ["README"]],
        ["lib", nil, ["Artistic"]],
        ["Pod-Escapes", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["Pod-Usage", nil, ["README"]],
        ["base", "Perl-5", ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["Encode", nil, ["AUTHORS"]],
        ["Moo", nil, ["README"]],
        ["Role-Tiny", nil, ["README"]],
        ["Try-Tiny", nil, ["LICENCE"]],
        ["Module-Metadata", nil, ["LICENCE"]],
        ["constant", nil, ["README"]],
        ["Module-Runtime", nil, ["README"]],
        ["ExtUtils-Install", nil, ["README"]],
        ["File-Path", nil, ["README"]],
        ["Getopt-Long", "Perl-5", ["README"]],
        ["ExtUtils-ParseXS", "Perl-5", ["README"]],
        ["version", nil, ["README"]],
        ["Data-Dumper", "Perl-5", ["Dumper.pm"]],
        ["Test-Harness", nil, ["README"]],
        ["Text-ParseWords", nil, ["README"]],
        ["Devel-GlobalDestruction", nil, ["README"]],
        ["XSLoader", nil, ["README"]],
        ["IPC-Cmd", nil, ["README"]],
        ["Pod-Parser", "Perl-5", ["README"]],
        ["Config-GitLike", nil, ["lib/Config/GitLike.pm"]],
        ["Test-Exception", nil, ["lib/Test/Exception.pm"]],
        ["MooX-Types-MooseLike", nil, ["README"]],
        ["String-ShellQuote", "Perl-5", ["README"]],
        ["Time-HiRes", nil, ["README"]],
        ["Test", "Perl-5", ["README"]],
        ["parent", nil, ["lib/parent.pm"]],
        ["MIME-Base64", nil, ["README"]],
        ["Sub-Identify", nil, ["lib/Sub/Identify.pm"]],
        ["namespace-autoclean", nil, ["README"]],
        ["B-Hooks-EndOfScope", nil, ["README"]],
        ["namespace-clean", nil, ["lib/namespace/clean.pm"]],
        ["Test-Deep", nil, ["lib/Test/Deep.pm"]],
        ["IO-Pager", "Perl-5", ["README"]],
        ["libintl-perl", "GPL-3.0", ["COPYING"]],
        ["Storable", "Perl-5", ["README"]],
        ["Test-Warnings", "Artistic-1.0", ["LICENCE"]],
        ["Test-Dir", nil, ["README"]],
        ["Digest-SHA", nil, ["README"]],
        ["Test-File-Contents", nil, ["README"]],
        ["Digest-MD5", nil, ["README"]],
        ["Algorithm-Diff", "Perl-5", ["lib/Algorithm/Diff.pm"]],
        ["Encode-Locale", nil, ["README"]],
        ["Hash-Merge", nil, ["README"]],
        ["Clone", nil, ["README"]],
        ["URI-db", nil, ["README"]],
        ["URI-Nested", nil, ["README.md"]],
        ["Test-utf8", nil, ["README"]],
        ["Class-Singleton", "Perl-5", ["README"]],
        ["Devel-PPPort", nil, ["README"]],
        ["Digest-SHA1", nil, ["README"]],
        ["JSON-PP", nil, ["README"]],
        ["MRO-Compat", nil, ["README"]],
        ["MouseX-NativeTraits", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["MouseX-Types", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["MouseX-Types-Path-Class", nil, ["http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt"]],
        ["Test-UseAllModules", nil, ["README"]],
        ["Variable-Magic", nil, ["README"]],
        ["Class-Data-Inheritable", nil, ["https://raw.githubusercontent.com/tmtmtmtm/class-data-inheritable/master/README"]],
      ].each do |override_data|
        override_license "perl_cpanm", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end

      # erlang_rebar
      [
        ["sync", "MIT", ["https://raw.githubusercontent.com/rustyio/sync/11df81d196eaab2d84caa3fbe8def5d476ef79d8/src/sync.erl"]],
        ["rebar_vsn_plugin", "Apache-2.0", ["https://raw.githubusercontent.com/erlware/rebar_vsn_plugin/master/src/rebar_vsn_plugin.erl"]],
        ["edown", "Erlang-Public", ["https://raw.githubusercontent.com/seth/edown/master/NOTICE"]],
        ["bcrypt", "Multiple", ["https://github.com/chef/erlang-bcrypt/blob/master/LICENSE"]],
        ["amqp_client", "MPL-2.0", ["https://raw.githubusercontent.com/seth/amqp_client/7622ad8093a41b7288a1aa44dd16d3e92ce8f833/src/amqp_connection.erl"]],
        ["erlsom", "LGPL-3.0", ["https://raw.githubusercontent.com/willemdj/erlsom/c5ca9fca1257f563d78b048e35ac60832ec80584/COPYING", "https://raw.githubusercontent.com/willemdj/erlsom/c5ca9fca1257f563d78b048e35ac60832ec80584/COPYING.LESSER"]],
        ["gen_server2", "Public-Domain", ["https://raw.githubusercontent.com/mdaguete/gen_server2/master/README.md"]],
        ["opscoderl_folsom", "Apache-2.0", ["https://raw.githubusercontent.com/chef/opscoderl_folsom/master/README.md"]],
        ["quickrand", "BSD-2-Clause", ["https://raw.githubusercontent.com/okeuday/quickrand/master/README.markdown"]],
        ["rabbit_common", "MPL-2.0", ["https://raw.githubusercontent.com/muxspace/rabbit_common/master/include/rabbit_msg_store.hrl"]],
        ["uuid", "BSD-2-Clause", ["https://raw.githubusercontent.com/okeuday/uuid/master/README.markdown"]],
        ["ibrowse", "BSD-2-Clause", nil],
        ["eunit_formatters", "Apache-2.0", ["https://raw.githubusercontent.com/seancribbs/eunit_formatters/master/README.md"]],
        ["erlware_commons", "MIT", ["https://raw.githubusercontent.com/erlware/erlware_commons/master/COPYING"]],
        ["getopt", "MIT", nil],
        ["relx", "Apache-2.0", ["https://raw.githubusercontent.com/erlware/relx/master/LICENSE.md"]],
      ].each do |override_data|
        override_license "erlang_rebar", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end

      # js_npm
      [
        ["isarray", nil, [canonical("MIT")]],
        ["array-filter", nil, [canonical("MIT")]],
        ["chokidar", nil, ["README.md"]],
        ["set-immediate-shim", "MIT", ["https://raw.githubusercontent.com/sindresorhus/set-immediate-shim/master/license"]],
        ["process-nextick-args", nil, [canonical("MIT")]],
        ["buffer-shims", nil, [canonical("MIT")]],
        ["brace-expansion", nil, ["README.md"]],
        ["verror", "MIT", ["https://github.com/joyent/node-verror/blob/master/LICENSE"]],
        # From the json-schema readme:
        # Code is licensed under the AFL or BSD license as part of the
        # Persevere project which is administered under the Dojo foundation,
        # and all contributions require a Dojo CLA.
        ["json-schema", "BSD", ["https://raw.githubusercontent.com/dojo/dojo/master/LICENSE"]],
        ["tweetnacl", "BSD", ["https://raw.githubusercontent.com/dchest/tweetnacl-js/master/COPYING.txt"]],
        ["assert-plus", "MIT", ["README.md"]],
        ["sntp", "BSD-3-Clause", nil],
        ["node-uuid", "MIT", nil],
        ["ms", "MIT", nil],
        ["jsonpointer", nil, ["https://raw.githubusercontent.com/janl/node-jsonpointer/master/LICENSE.md"]],
        ["has-color", nil, ["https://raw.githubusercontent.com/chalk/supports-color/master/license"]],
        ["generate-function", nil, ["https://github.com/mafintosh/generate-function/blob/master/LICENSE"]],
        ["extsprintf", "MIT", nil],
        ["dashdash", nil, ["https://raw.githubusercontent.com/trentm/node-dashdash/master/LICENSE.txt"]],
        # The link here is what's included in the readme
        ["async-each", nil, ["https://raw.githubusercontent.com/paulmillr/mit/master/README.md"]],
        # README on https://www.npmjs.com/package/indexof just says "MIT"
        ["indexof", "MIT", [canonical("MIT")]],
        ["querystring", "MIT", nil],
        ["timers-browserify", "MIT", nil],
        ["shell-quote", nil, ["https://raw.githubusercontent.com/substack/node-shell-quote/master/LICENSE"]],
        ["querystring-es3", "MIT", nil],
        ["xtend", "MIT", nil],
        ["source-map", nil, ["https://raw.githubusercontent.com/mozilla/source-map/master/LICENSE"]],
        ["randombytes", nil, [canonical("MIT")]],
        ["public-encrypt", nil, [canonical("MIT")]],
        ["parse-asn1", nil, [canonical("ISC")]],
        ["evp_bytestokey", nil, [canonical("MIT")]],
        ["cipher-base", nil, [canonical("MIT")]],
        ["asn1.js", nil, ["README.md"]],
        ["minimalistic-assert", nil, [canonical("ISC")]],
        ["bn.js", nil, ["README.md"]],
        ["diffie-hellman", nil, [canonical("MIT")]],
        ["miller-rabin", nil, ["README.md"]],
        ["brorand", nil, ["README.md"]],
        ["create-hmac", nil, [canonical("MIT")]],
        ["create-hash", nil, [canonical("MIT")]],
        ["ripemd160", nil, ["https://github.com/crypto-browserify/ripemd160/blob/master/LICENSE.md"]],
        ["create-ecdh", nil, [canonical("MIT")]],
        ["elliptic", nil, ["README.md"]],
        ["hash.js", nil, ["README.md"]],
        ["adm-zip", nil, ["https://raw.githubusercontent.com/cthackers/adm-zip/master/MIT-LICENSE.txt"]],
        ["after", "MIT", nil],
        ["agent-base", nil, ["README.md"]],
        ["angular2-cookie", "MIT", ["https://raw.githubusercontent.com/salemdar/angular2-cookie/master/LICENSE"]],
        ["angular-embedly", "BSD-2-Clause", nil],
        ["angular-feature-flags", nil, ["https://mjt01.mit-license.org/"]],
        ["angular-restmod", "MIT", nil],
        ["angular-spinner", nil, [canonical("MIT")]],
        ["angular2-router-loader", "MIT", ["README.md"]],
        ["ansi", "MIT", ["https://raw.githubusercontent.com/TooTallNate/ansi.js/master/LICENSE"]],
        ["ansi-regex", nil, ["https://raw.githubusercontent.com/chalk/ansi-regex/master/license"]],
        ["ansi-styles", nil, [canonical("MIT")]],
        ["ansi_up", "MIT", ["Readme.md"]],
        ["are-we-there-yet", nil, ["https://raw.githubusercontent.com/iarna/are-we-there-yet/master/LICENSE"]],
        ["arraybuffer.slice", "MIT", ["README.md"]],
        ["asn1", "MIT", nil],
        ["async-foreach", "MIT", nil],
        ["aws-sign2", "Apache-2.0", nil],
        ["babel", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-code-frame", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-core", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-generator", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helper-call-delegate", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helper-define-map", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helper-function-name", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helper-get-function-arity", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helper-hoist-variables", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helper-optimise-call-expression", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helper-regex", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helper-replace-supers", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-helpers", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-messages", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-check-es2015-constants", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-syntax-async-functions", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-arrow-functions", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-block-scoped-functions", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-block-scoping", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-classes", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-computed-properties", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-destructuring", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-duplicate-keys", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-for-of", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-function-name", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-literals", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-modules-amd", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-modules-commonjs", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-modules-systemjs", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-modules-umd", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-object-super", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-parameters", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-shorthand-properties", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-spread", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-sticky-regex", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-template-literals", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-typeof-symbol", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-es2015-unicode-regex", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-plugin-transform-strict-mode", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-preset-es2015", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-register", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-runtime", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-template", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-traverse", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["babel-types", nil, ["https://raw.githubusercontent.com/babel/babel/master/LICENSE"]],
        ["backo2", nil, ["https://raw.githubusercontent.com/mokesmokes/backo/master/LICENSE"]],
        ["balanced-match", nil, ["https://raw.githubusercontent.com/juliangruber/balanced-match/master/LICENSE.md"]],
        ["base64id", "MIT", ["https://raw.githubusercontent.com/faeldt/base64id/master/LICENSE"]],
        ["batch", nil, ["Readme.md"]],
        ["bcrypt-pbkdf", nil, [canonical("BSD-4-Clause")]],
        ["better-assert", "MIT", ["https://raw.githubusercontent.com/tj/better-assert/master/LICENSE"]],
        ["binary", nil, [canonical("MIT")]],
        ["bindings", nil, ["README.md"]],
        ["blob", "MIT", ["https://raw.githubusercontent.com/webmodules/blob/master/LICENSE"]],
        ["bluebird", nil, ["https://github.com/petkaantonov/bluebird/blob/master/LICENSE"]],
        ["browserify-cipher", nil, [canonical("MIT")]],
        ["browserify-des", nil, [canonical("MIT")]],
        ["browserify-zlib", nil, ["https://raw.githubusercontent.com/devongovett/browserify-zlib/master/LICENSE"]],
        ["buffers", "MIT", [canonical("MIT")]],
        ["bufferutil", nil, [canonical("MIT")]],
        ["builtins", nil, ["https://raw.githubusercontent.com/juliangruber/builtins/master/License"]],
        ["cached-path-relative", "MIT", ["Readme.md"]],
        # https://www.npmjs.com/package/callsite
        ["callsite", "MIT", [canonical("MIT")]],
        ["caseless", nil, ["https://github.com/request/caseless/blob/master/LICENSE"]],
        ["chainsaw", nil, ["https://raw.githubusercontent.com/substack/node-chainsaw/master/LICENSE", canonical("MIT")]],
        ["chalk", nil, ["https://raw.githubusercontent.com/chalk/chalk/master/license"]],
        ["cli", nil, ["README.md"]],
        ["cloneextend", "MIT", [canonical("MIT")]],
        ["combined-stream", "MIT", nil],
        ["commander", nil, ["https://github.com/tj/commander.js/blob/master/LICENSE"]],
        ["commondir", nil, ["https://raw.githubusercontent.com/substack/node-commondir/master/LICENSE"]],
        ["component-bind", "MIT", ["https://raw.githubusercontent.com/component/bind/master/LICENSE"]],
        ["component-emitter", "MIT", ["https://raw.githubusercontent.com/component/emitter/master/LICENSE"]],
        ["component-inherit", "MIT", ["https://github.com/component/inherit/blob/master/LICENSE"]],
        ["constants-browserify", nil, ["README.md"]],
        ["cookie-signature", nil, ["Readme.md"]],
        ["core-util-is", nil, ["https://raw.githubusercontent.com/isaacs/core-util-is/master/LICENSE"]],
        ["ctype", "MIT", nil],
        ["custom-event", nil, [canonical("MIT")]],
        ["delayed-stream", "MIT", nil],
        ["des.js", nil, ["README.md"]],
        ["dom-serialize", nil, [canonical("MIT")]],
        ["domelementtype", "BSD-2-Clause", nil],
        ["domhandler", "BSD-2-Clause", nil],
        ["domutils", "BSD-2-Clause", nil],
        ["engine.io-parser", "MIT", nil],
        ["esprima-fb", nil, ["https://raw.githubusercontent.com/facebookarchive/esprima/fb-harmony/LICENSE.BSD"]],
        ["falafel", nil, [canonical("MIT")]],
        ["filename-regex", nil, ["https://raw.githubusercontent.com/regexhq/filename-regex/master/LICENSE"]],
        ["font-awesome", nil, ["http://scripts.sil.org/OFL", canonical("MIT")]],
        ["get-caller-file", nil, [canonical("ISC")]],
        ["get-stdin", nil, ["https://raw.githubusercontent.com/sindresorhus/get-stdin/master/license"]],
        ["has-ansi", nil, ["https://raw.githubusercontent.com/chalk/has-ansi/master/license"]],
        ["has-cors", nil, [canonical("MIT")]],
        ["hat", nil, [canonical("MIT")]],
        ["https-proxy-agent", nil, ["README.md"]],
        ["inherits", "ISC", nil],
        ["invariant", nil, [canonical("BSD-3-Clause")]],
        ["invert-kv", nil, ["https://raw.githubusercontent.com/sindresorhus/invert-kv/master/license"]],
        ["jasmine", nil, [canonical("MIT")]],
        ["jasmine-core", nil, ["https://raw.githubusercontent.com/jasmine/jasmine/master/MIT.LICENSE"]],
        ["json5", nil, [canonical("MIT")]],
        ["jsonify", nil, ["https://raw.githubusercontent.com/substack/jsonify/master/readme.markdown"]],
        ["keymaster", "MIT", nil],
        ["loose-envify", nil, [canonical("MIT")]],
        ["natives", nil, [canonical("ISC")]],
        ["object-component", "MIT", [canonical("MIT")]],
        ["options", "MIT", ["README.md"]],
        ["over", nil, ["README.md"]],
        ["parse-diff", "MIT", nil],
        ["parsejson", nil, ["https://raw.githubusercontent.com/get/parsejson/master/LICENSE"]],
        ["parseqs", nil, ["https://raw.githubusercontent.com/get/querystring/master/LICENSE"]],
        ["parseuri", nil, ["https://raw.githubusercontent.com/get/parseuri/master/LICENSE"]],
        ["regenerator-runtime", nil, ["https://raw.githubusercontent.com/facebook/regenerator/master/LICENSE"]],
        ["rx", nil, ["https://raw.githubusercontent.com/Reactive-Extensions/RxJS/master/license.txt"]],
        ["sass-graph", nil, [canonical("MIT")]],
        ["sauce-connect-launcher", "MIT", ["README.md"]],
        ["saucelabs", "MIT", ["README.md"]],
        ["slash", nil, ["https://raw.githubusercontent.com/sindresorhus/slash/master/license"]],
        ["socket.io-parser", nil, ["https://raw.githubusercontent.com/socketio/socket.io-parser/master/LICENSE"]],
        ["stable", nil, ["README.md"]],
        ["strip-ansi", nil, ["https://raw.githubusercontent.com/chalk/strip-ansi/master/license"]],
        ["stubby", nil, ["https://raw.githubusercontent.com/mrak/stubby4node/master/APACHE.LICENSE"]],
        ["supports-color", nil, ["https://raw.githubusercontent.com/chalk/supports-color/master/license"]],
        ["tmp", nil, ["https://raw.githubusercontent.com/raszi/node-tmp/master/LICENSE"]],
        ["umd", nil, ["https://raw.githubusercontent.com/ForbesLindesay/umd/master/LICENSE"]],
        ["underscore.string", nil, ["README.markdown"]],
        ["utf-8-validate", nil, [canonical("MIT")]],
        ["w3c-blob", nil, [canonical("MIT")]],
        ["wordwrap", nil, ["https://raw.githubusercontent.com/substack/node-wordwrap/master/LICENSE"]],
        ["ws", nil, ["README.md"]],
        ["delivery-web", "Chef-MLSA", ["https://www.chef.io/online-master-agreement/"]],
        ["Insights", "Chef-MLSA", ["https://www.chef.io/online-master-agreement/"]],
        ["angular2-moment", nil, ["https://raw.githubusercontent.com/urish/angular2-moment/master/LICENSE"]],
        ["array-differ", nil, ["readme.md"]],
        ["babel-polyfill", nil, [canonical("MIT")]],
        ["boolbase", nil, ["https://raw.githubusercontent.com/fb55/boolbase/master/LICENSE"]],
        ["caller-path", nil, ["readme.md"]],
        ["callsites", nil, ["readme.md"]],
        ["capture-stack-trace", nil, ["readme.md"]],
        ["charenc", "MIT", nil],
        ["clipboard", nil, ["readme.md"]],
        ["closest", nil, ["README.md"]],
        ["coa", nil, [canonical("MIT")]],
        ["codelyzer", nil, ["README.md"]],
        ["color-convert", "MIT", nil],
        ["compression-webpack-plugin", nil, ["README.md"]],
        ["configstore", nil, ["readme.md"]],
        ["crypt", "MIT", nil],
        ["css-color-names", nil, ["README.md"]],
        ["css-loader", nil, ["README.md"]],
        ["css-selector-tokenizer", "MIT", ["README.md"]],
        ["delegate", "MIT", ["readme.md"]],
        ["enhanced-resolve", nil, ["https://raw.githubusercontent.com/webpack/enhanced-resolve/master/README.md"]],
        ["errno", nil, ["README.md"]],
        ["es6-promise-loader", nil, ["README.md"]],
        ["es6-promisify", nil, ["README.md"]],
        ["esrecurse", nil, ["https://raw.githubusercontent.com/estools/esrecurse/master/README.md"]],
        ["exit-hook", nil, ["readme.md"]],
        ["exports-loader", nil, ["README.md"]],
        ["expose-loader", nil, ["README.md"]],
        ["extract-text-webpack-plugin", nil, ["README.md"]],
        ["extract-zip", nil, [canonical("BSD-2-Clause")]],
        ["fastparse", nil, ["README.md"]],
        ["faye-websocket", "MIT", ["README.md"]],
        ["file-loader", nil, ["README.md"]],
        ["good-listener", nil, ["readme.md"]],
        ["html-comment-regex", nil, ["README.md"]],
        ["http-proxy-agent", nil, ["README.md"]],
        ["icss-replace-symbols", nil, ["README.md"]],
        ["imports-loader", nil, ["README.md"]],
        ["imurmurhash", nil, ["README.md"]],
        ["inquirer", nil, ["README.md"]],
        ["is-npm", nil, ["readme.md"]],
        ["is-path-cwd", nil, ["readme.md"]],
        ["is-path-in-cwd", nil, ["readme.md"]],
        ["is-path-inside", nil, ["readme.md"]],
        ["istanbul", nil, ["README.md"]],
        ["istanbul-instrumenter-loader", nil, ["README.md"]],
        ["karma-webpack", nil, ["README.md"]],
        ["lowercase-keys", nil, ["readme.md"]],
        ["macaddress", nil, [canonical("MIT")]],
        ["make-error", nil, ["README.md"]],
        ["matches-selector", nil, ["Readme.md"]],
        ["memory-fs", "MIT", ["README.md"]],
        ["mime", "MIT", nil],
        ["multipipe", nil, ["Readme.md"]],
        ["ncname", nil, ["readme.md"]],
        ["ng2-gravatar-directive", nil, ["README.md"]],
        ["ng2-pagination", nil, ["readme.md"]],
        ["node-libs-browser", nil, [canonical("MIT")]],
        ["nth-check", nil, ["README.md"]],
        ["phantomjs-polyfill", nil, [canonical("ISC")]],
        ["postcss-modules-extract-imports", nil, ["README.md"]],
        ["postcss-modules-scope", nil, ["README.md"]],
        ["postcss-modules-values", nil, ["README.md"]],
        ["progress", "MIT", nil],
        ["raw-loader", nil, ["README.md"]],
        ["readline2", nil, ["README.md"]],
        ["require-uncached", nil, ["readme.md"]],
        ["ripemd160", "MIT", ["https://raw.githubusercontent.com/crypto-browserify/ripemd160/master/LICENSE.md"]],
        ["rx-lite", nil, ["readme.md"]],
        ["select", "MIT", ["readme.md"]],
        ["source-list-map", nil, ["README.md"]],
        ["source-map-loader", nil, ["README.md"]],
        ["stream-cache", "MIT", ["https://raw.githubusercontent.com/felixge/node-stream-cache/master/License"]],
        ["style-loader", nil, ["README.md"]],
        ["tapable", nil, [canonical("MIT")]],
        ["throttleit", nil, ["Readme.md"]],
        ["timed-out", nil, ["readme.md"]],
        ["tiny-emitter", nil, [canonical("MIT")]],
        ["tryit", nil, ["README.md"]],
        ["ts-helper", nil, [canonical("MIT")]],
        ["tsify", "MIT", ["README.md"]],
        ["tslint-loader", nil, ["README.md"]],
        ["tv4", "Public-Domain", ["README.md"]],
        ["uglify-js", "MIT", nil],
        ["uniqid", nil, ["Readme.md"]],
        ["uniqs", nil, ["README.md"]],
        ["update-notifier", nil, ["readme.md"]],
        ["url-loader", nil, ["README.md"]],
        ["utila", nil, ["https://raw.githubusercontent.com/AriaMinaei/utila/master/LICENSE"]],
        ["watchpack", nil, ["https://raw.githubusercontent.com/webpack/watchpack/master/LICENSE"]],
        ["webpack-core", nil, ["README.md"]],
        ["webpack-dev-middleware", nil, [canonical("MIT")]],
        ["webpack-dev-server", nil, [canonical("MIT")]],
        ["webpack-sources", nil, [canonical("MIT")]],
        ["websocket-driver", nil, ["README.md"]],
        ["websocket-extensions", nil, ["README.md"]],
        ["xml-char-classes", nil, ["readme.md"]],
        ["zip-object", nil, [canonical("MIT")]],
        ["component-closest", nil, ["https://raw.githubusercontent.com/component/closest/master/README.md"]],
        ["component-matches-selector", nil, ["https://raw.githubusercontent.com/component/matches-selector/master/Readme.md"]],
        ["component-query", nil, ["https://raw.githubusercontent.com/component/query/master/Readme.md"]],
      ].each do |override_data|
        override_license "js_npm", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end

      override_license "js_npm", "debug" do |version|
        filename = "README.md"

        # 2.3 renames Readme to README; all previous are Readme
        if version =~ /^(0|1|2\.[0-3])/
          filename = "Readme.md"
        end

        {
          license_files: [ filename ],
          license: "MIT"
        }
      end

      # go_godep
      [
        ["github.com/agnivade/easy-scrypt", "MIT", nil],
        ["github.com/antonholmquist/jason", "MIT", nil],
        ["github.com/codegangsta/cli", "MIT", nil],
        ["github.com/codegangsta/inject", "MIT", nil],
        ["github.com/codeskyblue/go-sh", "Apache-2.0", nil],
        ["github.com/coreos/go-oidc/http", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/jose", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/key", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/oauth2", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/oidc", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-systemd/journal", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-systemd/master/LICENSE"]],
        ["github.com/coreos/pkg/capnslog", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/coreos/pkg/health", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/coreos/pkg/httputil", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/coreos/pkg/timeutil", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/dgrijalva/jwt-go", "MIT", nil],
        ["github.com/gin-gonic/gin", "MIT", nil],
        ["github.com/gin-gonic/gin/binding", "MIT", ["https://raw.githubusercontent.com/gin-gonic/gin/master/LICENSE"]],
        ["github.com/gin-gonic/gin/render", "MIT", ["https://raw.githubusercontent.com/gin-gonic/gin/master/LICENSE"]],
        ["github.com/go-sql-driver/mysql", "MPL-2.0", ["https://raw.githubusercontent.com/go-sql-driver/mysql/master/LICENSE"]],
        ["github.com/gorhill/cronexpr", "Apache-2.0", ["https://www.apache.org/licenses/LICENSE-2.0"]],
        ["github.com/jonboulle/clockwork", "Apache-2.0", nil],
        ["github.com/lib/pq", "MIT", nil],
        ["github.com/lib/pq/oid", "MIT", ["https://raw.githubusercontent.com/lib/pq/master/LICENSE.md"]],
        ["github.com/manucorporat/sse", "MIT", nil],
        ["github.com/mattn/go-colorable", "MIT", ["https://raw.githubusercontent.com/mattn/go-colorable/master/LICENSE"]],
        ["github.com/mattn/go-isatty", "MIT", nil],
        ["github.com/mattn/go-sqlite3", "MIT", nil],
        ["github.com/nu7hatch/gouuid", "MIT", nil],
        ["github.com/op/go-logging", "BSD-3-Clause", nil],
        ["golang.org/x/crypto/pbkdf2", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/crypto/master/LICENSE"]],
        ["golang.org/x/crypto/scrypt", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/crypto/master/LICENSE"]],
        ["golang.org/x/crypto/ssh", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/crypto/master/LICENSE"]],
        ["golang.org/x/net/context", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["golang.org/x/net/netutil", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["golang.org/x/net/context", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["golang.org/x/sys/unix", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/sys/master/LICENSE"]],
        ["gopkg.in/bluesuncorp/validator.v5", "MIT", ["https://raw.githubusercontent.com/go-playground/validator/v5/LICENSE"]],
        ["gopkg.in/gorp.v1", "MIT", ["https://raw.githubusercontent.com/go-gorp/gorp/v1.7.1/LICENSE"]],
        ["gopkg.in/tylerb/graceful.v1", "MIT", ["https://raw.githubusercontent.com/tylerb/graceful/v1.2.13/LICENSE"]],
      ].each do |override_data|
        override_license "go_godep", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end
    end

  end
end
