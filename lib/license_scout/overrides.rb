#
# Copyright:: Copyright 2016-2020, Chef Software Inc.
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

require "pathname" unless defined?(Pathname)

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
        if File.exist?(full_path)
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
      # AWS Ruby SDK
      aws_sdk_gems = %w{
          aws-eventstream
          aws-partitions
          aws-sdk
          aws-sdk-acm
          aws-sdk-acmpca
          aws-sdk-alexaforbusiness
          aws-sdk-amplify
          aws-sdk-apigateway
          aws-sdk-apigatewaymanagementapi
          aws-sdk-apigatewayv2
          aws-sdk-applicationautoscaling
          aws-sdk-applicationdiscoveryservice
          aws-sdk-appmesh
          aws-sdk-appstream
          aws-sdk-appsync
          aws-sdk-athena
          aws-sdk-autoscaling
          aws-sdk-autoscalingplans
          aws-sdk-backup
          aws-sdk-batch
          aws-sdk-budgets
          aws-sdk-chime
          aws-sdk-cloud9
          aws-sdk-clouddirectory
          aws-sdk-cloudformation
          aws-sdk-cloudfront
          aws-sdk-cloudhsm
          aws-sdk-cloudhsmv2
          aws-sdk-cloudsearch
          aws-sdk-cloudsearchdomain
          aws-sdk-cloudtrail
          aws-sdk-cloudwatch
          aws-sdk-cloudwatchevents
          aws-sdk-cloudwatchlogs
          aws-sdk-codebuild
          aws-sdk-codecommit
          aws-sdk-codedeploy
          aws-sdk-codepipeline
          aws-sdk-codestar
          aws-sdk-cognitoidentity
          aws-sdk-cognitoidentityprovider
          aws-sdk-cognitosync
          aws-sdk-comprehend
          aws-sdk-comprehendmedical
          aws-sdk-configservice
          aws-sdk-connect
          aws-sdk-core
          aws-sdk-costandusagereportservice
          aws-sdk-costexplorer
          aws-sdk-databasemigrationservice
          aws-sdk-datapipeline
          aws-sdk-datasync
          aws-sdk-dax
          aws-sdk-devicefarm
          aws-sdk-directconnect
          aws-sdk-directoryservice
          aws-sdk-dlm
          aws-sdk-docdb
          aws-sdk-dynamodb
          aws-sdk-dynamodbstreams
          aws-sdk-ec2
          aws-sdk-ecr
          aws-sdk-ecs
          aws-sdk-efs
          aws-sdk-eks
          aws-sdk-elasticache
          aws-sdk-elasticbeanstalk
          aws-sdk-elasticloadbalancing
          aws-sdk-elasticloadbalancingv2
          aws-sdk-elasticsearchservice
          aws-sdk-elastictranscoder
          aws-sdk-emr
          aws-sdk-firehose
          aws-sdk-fms
          aws-sdk-fsx
          aws-sdk-gamelift
          aws-sdk-glacier
          aws-sdk-globalaccelerator
          aws-sdk-glue
          aws-sdk-greengrass
          aws-sdk-guardduty
          aws-sdk-health
          aws-sdk-iam
          aws-sdk-importexport
          aws-sdk-inspector
          aws-sdk-iot
          aws-sdk-iot1clickdevicesservice
          aws-sdk-iot1clickprojects
          aws-sdk-iotanalytics
          aws-sdk-iotdataplane
          aws-sdk-iotjobsdataplane
          aws-sdk-kafka
          aws-sdk-kinesis
          aws-sdk-kinesisanalytics
          aws-sdk-kinesisanalyticsv2
          aws-sdk-kinesisvideo
          aws-sdk-kinesisvideoarchivedmedia
          aws-sdk-kinesisvideomedia
          aws-sdk-kms
          aws-sdk-lambda
          aws-sdk-lambdapreview
          aws-sdk-lex
          aws-sdk-lexmodelbuildingservice
          aws-sdk-lexruntimeservice
          aws-sdk-licensemanager
          aws-sdk-lightsail
          aws-sdk-machinelearning
          aws-sdk-macie
          aws-sdk-marketplacecommerceanalytics
          aws-sdk-marketplaceentitlementservice
          aws-sdk-marketplacemetering
          aws-sdk-mediaconnect
          aws-sdk-mediaconvert
          aws-sdk-medialive
          aws-sdk-mediapackage
          aws-sdk-mediastore
          aws-sdk-mediastoredata
          aws-sdk-mediatailor
          aws-sdk-migrationhub
          aws-sdk-mobile
          aws-sdk-mq
          aws-sdk-mturk
          aws-sdk-neptune
          aws-sdk-opsworks
          aws-sdk-opsworkscm
          aws-sdk-organizations
          aws-sdk-pi
          aws-sdk-pinpoint
          aws-sdk-pinpointemail
          aws-sdk-pinpointsmsvoice
          aws-sdk-polly
          aws-sdk-pricing
          aws-sdk-quicksight
          aws-sdk-ram
          aws-sdk-rds
          aws-sdk-rdsdataservice
          aws-sdk-redshift
          aws-sdk-rekognition
          aws-sdk-resourcegroups
          aws-sdk-resourcegroupstaggingapi
          aws-sdk-resources
          aws-sdk-robomaker
          aws-sdk-route53
          aws-sdk-route53domains
          aws-sdk-route53resolver
          aws-sdk-s3
          aws-sdk-s3control
          aws-sdk-sagemaker
          aws-sdk-sagemakerruntime
          aws-sdk-secretsmanager
          aws-sdk-securityhub
          aws-sdk-serverlessapplicationrepository
          aws-sdk-servicecatalog
          aws-sdk-servicediscovery
          aws-sdk-ses
          aws-sdk-shield
          aws-sdk-signer
          aws-sdk-simpledb
          aws-sdk-sfn
          aws-sdk-sms
          aws-sdk-snowball
          aws-sdk-sns
          aws-sdk-sqs
          aws-sdk-ssm
          aws-sdk-states
          aws-sdk-storagegateway
          aws-sdk-support
          aws-sdk-swf
          aws-sdk-textract
          aws-sdk-translate
          aws-sdk-transcribeservice
          aws-sdk-transcribestreamingservice
          aws-sdk-transfer
          aws-sdk-waf
          aws-sdk-wafregional
          aws-sdk-workdocs
          aws-sdk-worklink
          aws-sdk-workmail
          aws-sdk-workspaces
          aws-sdk-xray
          aws-sigv2
          aws-sigv4
      }.map { |aws_gem| [ aws_gem, nil, ["https://raw.githubusercontent.com/aws/aws-sdk-ruby/master/LICENSE.txt"] ] }

      # Default overrides for ruby_bundler dependency manager.
      other_gems = [
        ["transit-ruby", "Apache-2.0", ["LICENSE"]],
        ["binding_of_caller", "MIT", nil],
        ["bunny", "MIT", nil],
        ["chef-provisioning-aws", "Apache-2.0", ["LICENSE"]],
        ["chef-provisioning", "Apache-2.0", ["LICENSE"]],
        ["chef-rewind", "MIT", nil],
        ["chef-web-core", "Apache-2.0", nil],
        ["chef", "Apache-2.0", ["LICENSE"]],
        ["cheffish", "Apache-2.0", ["LICENSE"]],
        ["coderay", nil, ["README_INDEX.rdoc"]],
        ["debug_inspector", "MIT", ["README.md"]],
        ["em-http-request", "MIT", nil],
        ["equatable", "MIT", ["LICENSE.txt"]],
        ["erubis", "MIT", nil],
        ["formatador", "MIT", ["LICENSE.md"]],
        ["hana", "MIT", ["README.md"]],
        ["highline", "Ruby", ["LICENSE"]],
        ["httpclient", "Ruby", ["README.md"]],
        ["inifile", "MIT", ["README.md"]],
        ["ipaddress", "MIT", nil],
        ["jsonschema", "MIT", ["README.rdoc"]],
        ["knife-opc", "Apache-2.0", nil],
        ["little-plugger", "MIT", ["README.rdoc"]],
        ["logging", "MIT", ["README.md"]],
        ["lumberjack", "MIT", ["MIT_LICENSE.txt"]],
        ["m", "MIT", ["LICENSE"]],
        ["method_source", "MIT", nil],
        ["mixlib-authentication", "Apache-2.0", ["LICENSE"]],
        ["mixlib-cli", "Apache-2.0", ["LICENSE"]],
        ["mixlib-log", "Apache-2.0", ["LICENSE"]],
        ["mixlib-shellout", "Apache-2.0", ["LICENSE"]],
        ["moneta", "MIT", nil],
        ["mustermann", "MIT", ["LICENSE"]],
        ["mustermann-grape", "MIT", nil],
        ["net-http-persistent", "MIT", ["README.rdoc"]],
        ["net-http-pipeline", "MIT", ["README.txt"]],
        ["net-telnet", "Ruby", nil],
        ["netrc", "MIT", nil],
        ["oc-chef-pedant", "Apache-2.0", nil],
        ["ohai", "Apache-2.0", ["LICENSE"]],
        ["plist", "MIT", nil],
        ["proxifier", "MIT", nil],
        ["proxifier2", "MIT", nil],
        ["pry-remote", "MIT", nil],
        ["pry-stack_explorer", "MIT", nil],
        ["pry", "MIT", nil],
        ["puma", "BSD-3-Clause", nil],
        ["rack-test", "MIT", nil],
        ["rake", "MIT", nil],
        ["rb-inotify", "MIT", ["README.md"]],
        ["reel", "MIT", nil],
        ["rework-visit", "MIT", ["Readme.md"]],
        ["rework", "MIT", ["Readme.md"]],
        ["rspec", "MIT", nil],
        ["sequel", "MIT", nil],
        ["source-map-resolve", "MIT", ["LICENSE"]],
        ["source-map-url", "MIT", ["LICENSE"]],
        ["spork", "MIT", nil],
        ["syslog-logger", "MIT", ["README.rdoc"]],
        ["systemu", "BSD-2-Clause", nil],
        ["timeliness", "MIT", ["LICENSE"]],
        ["timers", "MIT", ["README.md"]],
        ["ubuntu_ami", "Apache-2.0", ["LICENSE"]],
        ["unicode_utils", "BSD-2-Clause", ["LICENSE.txt"]],
        ["unicorn", "Ruby", ["LICENSE"]],
        ["uuidtools", "Apache-2.0", nil],
        ["websocket", "MIT", ["README.md"]],
        ["winrm-fs", "Apache-2.0", nil],
        ["wisper", "MIT", ["README.md"]],
        ["yajl-ruby", "MIT", nil],
        # Overrides that require file fetching from internet
        ["amqp", "Ruby", ["https://raw.githubusercontent.com/ruby-amqp/amqp/master/README.md"]],
        ["aws-sigv4", "MIT", ["https://raw.githubusercontent.com/cmdrkeene/aws4/master/readme.md"]],
        ["bigdecimal", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/bigdecimal/v1.3.5/LICENSE.txt"]],
        ["blankslate", "MIT", ["https://raw.githubusercontent.com/masover/blankslate/master/MIT-LICENSE"]],
        ["codecov", "MIT", ["https://raw.githubusercontent.com/codecov/codecov-ruby/master/LICENSE.txt"]],
        ["citrus", "MIT", ["https://raw.githubusercontent.com/mjackson/citrus/master/README.md"]],
        ["coffee-script-source", nil, ["https://raw.githubusercontent.com/jessedoyle/coffee-script-source/master/LICENSE"]],
        ["compass", "MIT", ["https://raw.githubusercontent.com/Compass/compass/stable/LICENSE.markdown"]],
        ["cucumber-wire", nil, ["https://raw.githubusercontent.com/cucumber/cucumber-ruby-wire/master/LICENSE"]],
        ["date", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/date/master/README.md"]],
        ["dep_selector", nil, ["https://raw.githubusercontent.com/chef/dep-selector/master/LICENSE"]],
        ["enumerable-lazy", "MIT", ["https://raw.githubusercontent.com/yhara/enumerable-lazy/master/README.md"]],
        ["fast_xs", "MIT", ["https://raw.githubusercontent.com/brianmario/fast_xs/master/LICENSE"]],
        ["fuzzyurl", nil, ["https://raw.githubusercontent.com/gamache/fuzzyurl/master/LICENSE.txt"]],
        ["github_changelog_generator", nil, ["https://raw.githubusercontent.com/skywinder/github-changelog-generator/master/LICENSE"]],
        ["google-cloud-spanner", "Apache-2.0", ["https://raw.githubusercontent.com/GoogleCloudPlatform/google-cloud-ruby/master/LICENSE"]],
        ["google-gax", "BSD-3-Clause", ["https://raw.githubusercontent.com/googleapis/gax-ruby/master/LICENSE"]],
        ["google-protobuf", nil, ["https://raw.githubusercontent.com/google/protobuf/master/LICENSE"]],
        ["googleapis-common-protos-types", "Apache-2.0", ["https://raw.githubusercontent.com/googleapis/api-common-protos/master/LICENSE"]],
        ["googleapis-common-protos", "Apache-2.0", ["https://raw.githubusercontent.com/googleapis/googleapis/master/LICENSE"]],
        ["grpc-google-iam-v1", "Apache-2.0", ["https://raw.githubusercontent.com/googleapis/googleapis/master/LICENSE"]],
        ["grpc", "Apache-2.0", ["https://raw.githubusercontent.com/grpc/grpc/master/LICENSE"]],
        ["get_process_mem", "MIT", ["https://raw.githubusercontent.com/schneems/get_process_mem/master/README.md"]],
        ["hoe", "MIT", ["https://raw.githubusercontent.com/seattlerb/hoe/master/README.rdoc"]],
        ["html-proofer", "MIT", ["https://raw.githubusercontent.com/gjtorikian/html-proofer/main/LICENSE.txt"]],
        ["http-accept", "MIT", ["https://raw.githubusercontent.com/socketry/http-accept/master/README.md"]],
        ["http_parser.rb", nil, ["https://raw.githubusercontent.com/tmm1/http_parser.rb/master/LICENSE-MIT"]],
        ["inspec-msccm", nil, [canonical("Chef-MLSA")]],
        ["inspec-scap", nil, [canonical("Chef-MLSA")]],
        ["interception", "MIT", ["https://raw.githubusercontent.com/ConradIrwin/interception/master/LICENSE.MIT"]],
        ["io-wait", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/io-wait/master/COPYING"]],
        ["jaro_winkler", "MIT", ["https://raw.githubusercontent.com/tonytonyjan/jaro_winkler/master/LICENSE.txt"]],
        ["json_pure", nil, ["https://raw.githubusercontent.com/flori/json/master/README.md"]],
        ["jwt", nil, ["https://raw.githubusercontent.com/jwt/ruby-jwt/master/LICENSE"]],
        ["libv8", "MIT", ["https://raw.githubusercontent.com/rubyjs/libv8/master/README.md"]],
        ["lockfile", "Ruby", ["https://rubygems.org/gems/lockfile"]],
        ["minitar", "Ruby", ["https://raw.githubusercontent.com/atoulme/minitar/master/README"]],
        ["minitest", nil, ["https://raw.githubusercontent.com/seattlerb/minitest/master/README.rdoc"]],
        ["minitest-sprint", "MIT", ["https://raw.githubusercontent.com/seattlerb/minitest-sprint/master/README.rdoc"]],
        ["mocha", "MIT", ["https://raw.githubusercontent.com/freerange/mocha/master/MIT-LICENSE.md"]],
        ["multipart-post", "MIT", ["https://raw.githubusercontent.com/socketry/multipart-post/main/license.md"]],
        ["net-http-spy", "Public-Domain", ["https://raw.githubusercontent.com/martinbtt/net-http-spy/master/readme.markdown"]],
        ["net-protocol", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/net-protocol/master/LICENSE.txt"]],
        ["nio4r", "MIT", ["https://raw.githubusercontent.com/socketry/nio4r/master/readme.md"]],
        ["omniauth-chef", nil, ["https://raw.githubusercontent.com/chef/omniauth-chef/master/README.md"]],
        ["options", "Ruby", ["https://rubygems.org/gems/options"]],
        ["os", "MIT", ["https://raw.githubusercontent.com/rdp/os/master/LICENSE"]],
        ["overcommit", nil, ["https://raw.githubusercontent.com/brigade/overcommit/master/MIT-LICENSE"]],
        ["parser", "MIT", ["https://raw.githubusercontent.com/whitequark/parser/v2.7.2.0/LICENSE.txt"]],
        ["parslet", "MIT", ["https://raw.githubusercontent.com/kschiess/parslet/master/LICENSE"]],
        ["path_expander", "MIT", ["https://raw.githubusercontent.com/seattlerb/path_expander/master/README.rdoc"]],
        ["pbkdf2", "MIT", ["https://raw.githubusercontent.com/emerose/pbkdf2-ruby/master/LICENSE.TXT"]],
        ["rack-accept", "MIT", ["https://raw.githubusercontent.com/mjackson/rack-accept/master/README.md"]],
        ["rails-deprecated_sanitizer", nil, ["https://raw.githubusercontent.com/rails/rails-deprecated_sanitizer/master/LICENSE"]],
        ["rails-html-sanitizer", nil, ["https://raw.githubusercontent.com/rails/rails-html-sanitizer/master/MIT-LICENSE"]],
        ["rails", nil, ["https://raw.githubusercontent.com/rails/rails/master/README.md"]],
        ["railties", nil, ["https://raw.githubusercontent.com/rails/rails/master/railties/MIT-LICENSE"]],
        ["rchardet", "LGPL", ["https://raw.githubusercontent.com/jmhodges/rchardet/master/LGPL-LICENSE.txt"]],
        ["ref", "MIT", ["https://raw.githubusercontent.com/ruby-concurrency/ref/master/MIT_LICENSE"]],
        ["rdoc", "Ruby", ["https://raw.githubusercontent.com/ruby/rdoc/master/LICENSE.rdoc"]],
        ["rest-client", "MIT", ["https://raw.githubusercontent.com/rest-client/rest-client/master/LICENSE"]],
        ["rly", "MIT", ["https://raw.githubusercontent.com/farcaller/rly/master/LICENSE.txt"]],
        ["rspec-rerun", nil, ["https://raw.githubusercontent.com/dblock/rspec-rerun/master/LICENSE.md"]],
        ["ruby2_keywords", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/ruby2_keywords/master/LICENSE"]],
        ["rubyzip", nil, ["https://raw.githubusercontent.com/rubyzip/rubyzip/master/README.md"]],
        ["simplecov_json_formatter", "MIT", ["https://raw.githubusercontent.com/codeclimate-community/simplecov_json_formatter/master/LICENSE"]],
        ["sfl", "Ruby", ["https://raw.githubusercontent.com/ujihisa/spawn-for-legacy/master/LICENCE.md"]],
        ["slack-notifier", "MIT", ["https://raw.githubusercontent.com/stevenosloan/slack-notifier/master/LICENSE"]],
        ["sslshake", "MPL-2.0", ["https://raw.githubusercontent.com/arlimus/sslshake/master/README.md"]],
        ["sprockets", "MIT", ["https://raw.githubusercontent.com/rails/sprockets/master/MIT-LICENSE"]],
        ["sqlite3-ruby", "BSD-3", ["https://raw.githubusercontent.com/sparklemotion/sqlite3-ruby/master/LICENSE"]],
        ["strscan", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/strscan/master/LICENSE.txt"]],
        ["structured_warnings", "MIT", ["https://raw.githubusercontent.com/schmidt/structured_warnings/master/LICENSE.txt"]],
        ["therubyracer", "MIT", ["https://raw.githubusercontent.com/rubyjs/therubyracer/master/README.md"]],
        ["thin", "BSD-2-Clause", ["https://raw.githubusercontent.com/macournoyer/thin/master/README.md"]],
        ["time", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/time/master/LICENSE.txt"]],
        ["timeout", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/timeout/master/LICENSE.txt"]],
        ["unicorn-rails", "MIT", ["https://raw.githubusercontent.com/samuelkadolph/unicorn-rails/master/LICENSE"]],
        ["uri_template", "MIT", ["https://raw.githubusercontent.com/hannesg/uri_template/master/uri_template.gemspec"]],
        ["url", "MIT", ["https://raw.githubusercontent.com/tal/URL/master/LICENSE"]],
        ["websocket-driver", nil, ["https://raw.githubusercontent.com/faye/websocket-driver-ruby/master/LICENSE.md"]],
        ["websocket-extensions", nil, ["https://raw.githubusercontent.com/faye/websocket-extensions-ruby/master/LICENSE.md"]],
        ["win32-api", "Artistic-2.0", ["https://raw.githubusercontent.com/cosmo0920/win32-api/master/README.md"]],
        ["win32-dir", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-dir/ffi/README.md"]],
        ["win32-event", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-event/ffi/README"]],
        ["win32-eventlog", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-eventlog/ffi/README"]],
        ["win32-ipc", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-ipc/ffi/README.md"]],
        ["win32-mmap", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-mmap/ffi/README.md"]],
        ["win32-mutex", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-mutex/ffi/README.md"]],
        ["win32-process", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-process/ffi/README.md"]],
        ["win32-service", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-service/ffi/README.md"]],
        ["win32-taskscheduler", "Artistic-2.0", ["https://raw.githubusercontent.com/chef/win32-taskscheduler/ole/README.md"]],
        ["windows-api", "Artistic-2.0", ["https://raw.githubusercontent.com/cosmo0920/windows-api/master/README"]],
        ["word-salad", "MIT", ["https://raw.githubusercontent.com/alexvollmer/word_salad/master/README.txt"]],
        ["xml-simple", "MIT", ["https://raw.githubusercontent.com/maik/xml-simple/master/LICENSE"]],
        ["zonefile", "MIT", ["https://raw.githubusercontent.com/boesemar/zonefile/master/LICENSE"]],
        ["sync", "BSD-2-Clause", ["https://raw.githubusercontent.com/ruby/sync/master/LICENSE.txt"]],
        ["crack", "MIT", ["https://github.com/jnunemaker/crack/blob/master/LICENSE"]],
      ]
      (aws_sdk_gems + other_gems).each do |override_data|
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
        ["chef-sugar", nil, ["https://raw.githubusercontent.com/chef/chef-sugar/master/LICENSE"]],
        ["openssl", nil, ["https://raw.githubusercontent.com/chef-cookbooks/openssl/master/LICENSE"]],
        ["runit", nil, ["https://raw.githubusercontent.com/chef-cookbooks/runit/master/LICENSE"]],
        ["yum", nil, ["https://raw.githubusercontent.com/chef-cookbooks/yum/master/LICENSE"]],
        ["compat_resource", nil, ["https://raw.githubusercontent.com/chef-cookbooks/compat_resource/master/LICENSE"]],
        ["yum-epel", nil, ["https://raw.githubusercontent.com/chef-cookbooks/yum-epel/master/LICENSE"]],
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
        ["sqitch", "MIT", ["https://raw.githubusercontent.com/sqitchers/sqitch/develop/LICENSE.md"]],
        ["sqitch", "MIT", ["https://raw.githubusercontent.com/theory/sqitch/master/README.md"]],
        ["Scalar-List-Utils", nil, ["README"]],
        ["perl", nil, ["README"]],
        ["IO", nil, ["README"]],
        ["ExtUtils-MakeMaker", "Perl-5", ["http://www.perl.com/perl/misc/Artistic.html"]],
        ["PathTools", "Perl-5", ["lib/File/Spec.pm"]],
        ["Exporter", nil, ["README"]],
        ["Carp", nil, ["README"]],
        ["lib", nil, ["Artistic"]],
        ["Pod-Escapes", "Perl-5", ["lib/Pod/Escapes.pm"]],
        ["Pod-Usage", nil, ["README"]],
        ["base", "Perl-5", ["http://www.perl.com/perl/misc/Artistic.html"]],
        ["Encode", nil, ["AUTHORS"]],
        ["Moo", nil, ["README"]],
        ["Sub-Quote", nil, ["README"]],
        ["Role-Tiny", nil, ["README"]],
        ["Try-Tiny", nil, ["LICENCE"]],
        ["Module-Metadata", nil, ["LICENCE"]],
        ["constant", nil, ["README"]],
        ["Module-Runtime", nil, ["README"]],
        ["ExtUtils-Install", nil, ["README"]],
        ["File-Path", nil, ["README"]],
        ["Getopt-Long", "Perl-5", ["README"]],
        ["ExtUtils-ParseXS", "Perl-5", ["META.json"]],
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
        ["Hash-Merge", nil, ["README.md"]],
        ["Clone", nil, ["README"]],
        ["Clone-Choose", nil, ["README.md"]],
        ["URI-db", nil, ["README"]],
        ["URI-Nested", nil, ["README.md"]],
        ["Test-utf8", nil, ["README"]],
        ["Class-Singleton", "Perl-5", ["README"]],
        ["Devel-PPPort", "Perl-5", ["Makefile.PL"]],
        ["Digest-SHA1", nil, ["README"]],
        ["JSON-PP", nil, ["README"]],
        ["MRO-Compat", nil, ["README"]],
        ["MouseX-NativeTraits", "Artistic-1.0", ["lib/MouseX/NativeTraits.pm"]],
        ["MouseX-Types", "Artistic-1.0", ["lib/MouseX/Types.pm"]],
        ["MouseX-Types-Path-Class", "Artistic-1.0", ["lib/MouseX/Types/Path/Class.pm"]],
        ["Test-UseAllModules", nil, ["README"]],
        ["Variable-Magic", nil, ["README"]],
        ["Class-Data-Inheritable", nil, ["https://raw.githubusercontent.com/tmtmtmtm/class-data-inheritable/master/README"]],
        ["File-ShareDir", "Perl-5", ["lib/File/ShareDir.pm"]],
        ["TermReadKey", "nil", ["README"]],
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
        ["base16", "BSD-2-Clause", ["LICENSE"]],
        ["eini", "Apache-2.0", ["LICENSE"]],
        ["fs", "ISC", ["LICENSE"]],
        ["goldrush", "ISC", ["LICENSE"]],
        ["jsx", "MIT", ["LICENSE"]],
        ["recon", "BSD-3-Clause", ["LICENSE"]],
        ["sync", "MIT", ["https://raw.githubusercontent.com/rustyio/sync/11df81d196eaab2d84caa3fbe8def5d476ef79d8/src/sync.erl"]],
        ["rebar_vsn_plugin", "Apache-2.0", ["https://raw.githubusercontent.com/erlware/rebar_vsn_plugin/master/src/rebar_vsn_plugin.erl"]],
        ["edown", "Erlang-Public", ["https://raw.githubusercontent.com/seth/edown/master/NOTICE"]],
        ["bcrypt", "Multiple", ["https://raw.githubusercontent.com/chef/erlang-bcrypt/master/LICENSE"]],
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
        ["erlcloud", "BSD-2-Clause", ["https://raw.githubusercontent.com/erlcloud/erlcloud/master/COPYRIGHT"]],
        ["lhttpc", "BSD-3-Clause", ["https://raw.githubusercontent.com/erlcloud/lhttpc/master/LICENCE"]],
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
        ["ignore", "MIT", ["https://raw.githubusercontent.com/kaelzhang/node-ignore/master/LICENSE-MIT"]],
        ["hock", "MIT", nil],
        ["known-css-properties", nil, [canonical("MIT")]],
        ["buffer-indexof", "MIT", nil],
        ["stdout-stream", "MIT", nil],
        ["thunky", "MIT", [canonical("MIT")]],
        ["core-object", nil, [canonical("MIT")]],
        ["css-parse", nil, [canonical("MIT")]],
        ["denodeify", nil, [canonical("MIT")]],
        ["detect-node", nil, [canonical("MIT")]],
        ["ember-cli-normalize-entity-name", nil, [canonical("MIT")]],
        ["ember-cli-string-utils", nil, [canonical("MIT")]],
        ["ensure-posix-path", nil, [canonical("MIT")]],
        ["handle-thing", nil, [canonical("MIT")]],
        ["hash-base", nil, [canonical("MIT")]],
        ["heimdalljs", nil, [canonical("MIT")]],
        ["hmac-drbg", nil, [canonical("MIT")]],
        ["hpack.js", nil, [canonical("MIT")]],
        ["http-deceiver", nil, [canonical("MIT")]],
        ["icss-utils", nil, [canonical("MIT")]],
        ["inflection", nil, [canonical("MIT")]],
        ["ip", nil, [canonical("MIT")]],
        ["karma-source-map-support", nil, [canonical("MIT")]],
        ["loader-runner", nil, [canonical("MIT")]],
        ["magic-string", nil, [canonical("MIT")]],
        ["matcher-collection", nil, [canonical("MIT")]],
        ["minimalistic-crypto-utils", nil, [canonical("MIT")]],
        ["node-modules-path", nil, [canonical("MIT")]],
        ["obuf", nil, [canonical("MIT")]],
        ["rx-lite-aggregates", nil, [canonical("MIT")]],
        ["script-loader", nil, [canonical("MIT")]],
        ["select-hose", nil, [canonical("MIT")]],
        ["selfsigned", nil, [canonical("MIT")]],
        ["silent-error", nil, [canonical("MIT")]],
        ["spdy", nil, [canonical("MIT")]],
        ["spdy-transport", nil, [canonical("MIT")]],
        ["vlq", nil, [canonical("MIT")]],
        ["wbuf", nil, [canonical("MIT")]],
        ["copy-to-clipboard", nil, [canonical("MIT")]],
        ["toggle-selection", nil, [canonical("MIT")]],
        ["isarray", nil, [canonical("MIT")]],
        ["array-filter", nil, [canonical("MIT")]],
        ["cssauron", nil, [canonical("MIT")]],
        ["path-parse", nil, [canonical("MIT")]],
        ["semver-dsl", nil, [canonical("MIT")]],
        ["chokidar", nil, ["README.md"]],
        ["set-immediate-shim", "MIT", ["https://raw.githubusercontent.com/sindresorhus/set-immediate-shim/master/license"]],
        ["process-nextick-args", nil, [canonical("MIT")]],
        ["buffer-shims", nil, [canonical("MIT")]],
        ["brace-expansion", nil, ["README.md"]],
        ["verror", "MIT", ["https://raw.githubusercontent.com/joyent/node-verror/master/LICENSE"]],
        # From the json-schema readme:
        # Code is licensed under the AFL or BSD license as part of the
        # Persevere project which is administered under the Dojo foundation,
        # and all contributions require a Dojo CLA.
        ["json-schema", "BSD", ["https://raw.githubusercontent.com/dojo/dojo/master/LICENSE"]],
        ["tweetnacl", "BSD", ["https://raw.githubusercontent.com/dchest/tweetnacl-js/master/LICENSE"]],
        ["assert-plus", "MIT", ["README.md"]],
        ["sntp", "BSD-3-Clause", nil],
        ["node-uuid", "MIT", nil],
        ["ms", "MIT", nil],
        ["jsonpointer", nil, ["https://raw.githubusercontent.com/janl/node-jsonpointer/master/LICENSE.md"]],
        ["has-color", nil, ["https://raw.githubusercontent.com/chalk/supports-color/master/license"]],
        ["generate-function", nil, ["https://raw.githubusercontent.com/mafintosh/generate-function/master/LICENSE"]],
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
        ["browserify-aes", "MIT", ["https://raw.githubusercontent.com/crypto-browserify/browserify-aes/master/LICENSE"]],
        ["ripemd160", nil, ["https://raw.githubusercontent.com/crypto-browserify/ripemd160/master/LICENSE"]],
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
        ["bluebird", nil, ["https://raw.githubusercontent.com/petkaantonov/bluebird/master/LICENSE"]],
        ["browserify-cipher", nil, [canonical("MIT")]],
        ["browserify-des", nil, [canonical("MIT")]],
        ["browserify-zlib", nil, ["https://raw.githubusercontent.com/devongovett/browserify-zlib/master/LICENSE"]],
        ["buffers", "MIT", [canonical("MIT")]],
        ["bufferutil", nil, [canonical("MIT")]],
        ["builtins", nil, ["https://raw.githubusercontent.com/juliangruber/builtins/master/License"]],
        ["cached-path-relative", "MIT", ["Readme.md"]],
        # https://www.npmjs.com/package/callsite
        ["callsite", "MIT", [canonical("MIT")]],
        ["caseless", nil, ["https://raw.githubusercontent.com/request/caseless/master/LICENSE"]],
        ["chainsaw", nil, ["https://raw.githubusercontent.com/substack/node-chainsaw/master/LICENSE", canonical("MIT")]],
        ["chalk", nil, ["https://raw.githubusercontent.com/chalk/chalk/master/license"]],
        ["cli", nil, ["README.md"]],
        ["cloneextend", "MIT", [canonical("MIT")]],
        ["combined-stream", "MIT", nil],
        ["commander", nil, ["https://raw.githubusercontent.com/tj/commander.js/master/LICENSE"]],
        ["commondir", nil, ["https://raw.githubusercontent.com/substack/node-commondir/master/LICENSE"]],
        ["component-bind", "MIT", ["https://raw.githubusercontent.com/component/bind/master/LICENSE"]],
        ["component-emitter", "MIT", ["https://raw.githubusercontent.com/component/emitter/master/LICENSE"]],
        ["component-inherit", "MIT", ["https://raw.githubusercontent.com/component/inherit/master/LICENSE"]],
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
        ["ng2d3", "MIT", ["docs/license.md"]],
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
        ["delivery-web", "Chef-MLSA", [canonical("Chef-MLSA")]],
        ["visibility-web", "Chef-MLSA", [canonical("Chef-MLSA")]],
        ["compliance-ui-components", "Chef-MLSA", [canonical("Chef-MLSA")]],
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
        ["cssbeautify", nil, ["https://raw.githubusercontent.com/senchalabs/cssbeautify/master/README.md"]],
        ["csslint", nil, ["https://raw.githubusercontent.com/stubbornella/csslint/master/LICENSE"]],
        ["css-color-names", nil, ["README.md"]],
        ["css-loader", nil, ["README.md"]],
        ["css-selector-tokenizer", "MIT", ["README.md"]],
        ["delegate", "MIT", ["readme.md"]],
        ["enhanced-resolve", nil, ["https://raw.githubusercontent.com/webpack/enhanced-resolve/master/README.md"]],
        ["electron-releases", "MIT", ["readme.md"]],
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
        ["math-random", nil, [canonical("MIT")]],
        ["memory-fs", "MIT", ["README.md"]],
        ["mime", "MIT", nil],
        ["multipipe", nil, ["Readme.md"]],
        ["ncname", nil, ["readme.md"]],
        ["ng2-gravatar-directive", nil, ["README.md"]],
        ["ng2-pagination", nil, ["readme.md"]],
        ["node-libs-browser", nil, [canonical("MIT")]],
        ["nth-check", nil, ["README.md"]],
        ["parserlib", nil, ["https://raw.githubusercontent.com/CSSLint/parser-lib/master/LICENSE"]],
        ["phantomjs-polyfill", nil, [canonical("ISC")]],
        ["postcss-modules-extract-imports", nil, ["README.md"]],
        ["postcss-modules-scope", nil, ["README.md"]],
        ["postcss-modules-values", nil, ["README.md"]],
        ["progress", "MIT", nil],
        ["raw-loader", nil, ["README.md"]],
        ["readline2", nil, ["README.md"]],
        ["require-uncached", nil, ["readme.md"]],
        ["rework", "MIT", ["Readme.md"]],
        ["rework-visit", "MIT", ["Readme.md"]],
        ["ripemd160", "MIT", ["https://raw.githubusercontent.com/crypto-browserify/ripemd160/master/LICENSE"]],
        ["rx-lite", nil, ["readme.md"]],
        ["select", "MIT", ["readme.md"]],
        ["source-list-map", nil, ["README.md"]],
        ["source-map-loader", nil, ["README.md"]],
        ["source-map-resolve", "MIT", ["readme.md"]],
        ["source-map-url", "MIT", ["readme.md"]],
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
        ["wallaby-webpack", nil, [canonical("MIT")]],
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
        ["webcomponents.js", "BSD-3-Clause", ["https://raw.githubusercontent.com/webcomponents/webcomponentsjs/master/LICENSE.md"]],
        ["web-animations-js", "Apache-2.0", ["https://raw.githubusercontent.com/web-animations/web-animations-js/dev/COPYING"]],
        ["electron-to-chromium", nil, [canonical("ISC")]],
        ["debug", "MIT", ["https://raw.githubusercontent.com/visionmedia/debug/master/LICENSE"]],
        ["performance-now", "MIT", ["https://raw.githubusercontent.com/braveg1rl/performance-now/master/license.txt"]],
        ["cli-table", "MIT", ["README.md"]],
        ["process", "MIT", ["https://raw.githubusercontent.com/defunctzombie/node-process/master/LICENSE"]],
        ["rrule", "BSD-3-Clause", ["https://raw.githubusercontent.com/jakubroztocil/rrule/master/LICENCE"]],
        # jszip says it is dual licensed under MIT and GPLv3
        ["jszip", "MIT", ["https://raw.githubusercontent.com/Stuk/jszip/master/LICENSE.markdown"]],
        ["buffer-from", "MIT", ["https://raw.githubusercontent.com/LinusU/buffer-from/master/LICENSE"]],
        ["buffer-alloc", nil, [canonical("MIT")]],
        ["buffer-alloc-unsafe", nil, [canonical("MIT")]],
        ["buffer-fill", nil, [canonical("MIT")]],
        ["ipaddr.js", "MIT", ["https://raw.githubusercontent.com/whitequark/ipaddr.js/master/LICENSE"]],
        ["psl", "MIT", ["https://raw.githubusercontent.com/wrangr/psl/master/README.md"]],
        ["is-my-ip-valid", "MIT", ["https://raw.githubusercontent.com/LinusU/is-my-ip-valid/master/LICENSE"]],
        ["minipass", "ISC", ["https://raw.githubusercontent.com/isaacs/minipass/master/LICENSE"]],
        ["npm-bundled", "ISC", ["https://raw.githubusercontent.com/npm/npm-bundled/master/LICENSE"]],
        ["needle", "MIT", ["https://raw.githubusercontent.com/tomas/needle/master/license.txt"]],
        ["uri-js", "BSD-2-Clause", ["https://raw.githubusercontent.com/garycourt/uri-js/master/README.md"]],
      ].each do |override_data|
        override_license "js_npm", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end

      # go_godep
      [
        ["github.com/agnivade/easy-scrypt", "MIT", ["https://raw.githubusercontent.com/agnivade/easy-scrypt/master/LICENSE.txt"]],
        ["github.com/antonholmquist/jason", "MIT", ["https://raw.githubusercontent.com/antonholmquist/jason/master/LICENSE"]],
        ["github.com/aws/aws-sdk-go", "Apache-2.0", ["https://raw.githubusercontent.com/aws/aws-sdk-go/master/LICENSE.txt"]],
        ["github.com/beevik/etree", "BSD-2-Clause", ["https://raw.githubusercontent.com/beevik/etree/master/LICENSE"]],
        ["github.com/blang/semver", "MIT", ["https://raw.githubusercontent.com/blang/semver/master/LICENSE"]],
        ["github.com/BurntSushi/toml", "WTFPL", ["https://raw.githubusercontent.com/BurntSushi/toml/master/COPYING"]],
        ["github.com/codegangsta/cli", "MIT", ["https://raw.githubusercontent.com/urfave/cli/master/LICENSE"]],
        ["github.com/codegangsta/inject", "MIT", ["https://raw.githubusercontent.com/codegangsta/inject/master/LICENSE"]],
        ["github.com/codeskyblue/go-sh", "Apache-2.0", ["https://raw.githubusercontent.com/codeskyblue/go-sh/master/LICENSE"]],
        ["github.com/coreos/go-oidc", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/http", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/jose", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/key", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/oauth2", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-oidc/oidc", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-oidc/master/LICENSE"]],
        ["github.com/coreos/go-systemd/journal", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/go-systemd/master/LICENSE"]],
        ["github.com/coreos/pkg", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/coreos/pkg/capnslog", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/coreos/pkg/health", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/coreos/pkg/httputil", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/coreos/pkg/timeutil", "Apache-2.0", ["https://raw.githubusercontent.com/coreos/pkg/master/LICENSE"]],
        ["github.com/ctdk/chefcrypto", "Apache-2.0", ["https://raw.githubusercontent.com/ctdk/chefcrypto/master/LICENSE"]],
        ["github.com/ctdk/go-trie", "MIT", ["https://raw.githubusercontent.com/ctdk/go-trie/master/LICENSE"]],
        ["github.com/ctdk/goiardi", "Apache-2.0", ["https://raw.githubusercontent.com/ctdk/goiardi/master/LICENSE"]],
        ["github.com/dchest/siphash", "CC0-1.0", ["https://raw.githubusercontent.com/dchest/siphash/master/README.md"]],
        ["github.com/dgrijalva/jwt-go", "MIT", ["https://raw.githubusercontent.com/dgrijalva/jwt-go/master/LICENSE"]],
        ["github.com/fatih/structs", "MIT", ["https://raw.githubusercontent.com/fatih/structs/master/LICENSE"]],
        ["github.com/gin-gonic/gin", "MIT", ["https://raw.githubusercontent.com/gin-gonic/gin/master/LICENSE"]],
        ["github.com/gin-gonic/gin/binding", "MIT", ["https://raw.githubusercontent.com/gin-gonic/gin/master/LICENSE"]],
        ["github.com/gin-gonic/gin/render", "MIT", ["https://raw.githubusercontent.com/gin-gonic/gin/master/LICENSE"]],
        ["github.com/go-chef/chef", "Apache-2.0", ["https://raw.githubusercontent.com/go-chef/chef/master/LICENSE"]],
        ["github.com/go-ini/ini", "Apache-2.0", ["https://raw.githubusercontent.com/go-ini/ini/master/LICENSE"]],
        ["github.com/go-sql-driver/mysql", "MPL-2.0", ["https://raw.githubusercontent.com/go-sql-driver/mysql/master/LICENSE"]],
        ["github.com/golang/protobuf", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/protobuf/master/LICENSE"]],
        ["github.com/gorhill/cronexpr", "Apache-2.0", ["https://www.apache.org/licenses/LICENSE-2.0"]],
        ["github.com/gorilla/handlers", "BSD-2-Clause", ["https://raw.githubusercontent.com/gorilla/handlers/master/LICENSE"]],
        ["github.com/hashicorp/errwrap", "MPL-2.0", ["https://raw.githubusercontent.com/hashicorp/errwrap/master/LICENSE"]],
        ["github.com/hashicorp/go-cleanhttp", "MPL-2.0", ["https://raw.githubusercontent.com/hashicorp/go-cleanhttp/master/LICENSE"]],
        ["github.com/hashicorp/go-multierror", "MPL-2.0", ["https://raw.githubusercontent.com/hashicorp/go-multierror/master/LICENSE"]],
        ["github.com/hashicorp/go-rootcerts", "MPL-2.0", ["https://raw.githubusercontent.com/hashicorp/go-rootcerts/master/LICENSE"]],
        ["github.com/hashicorp/hcl", "MPL-2.0", ["https://raw.githubusercontent.com/hashicorp/hcl/master/LICENSE"]],
        ["github.com/hashicorp/vault", "MPL-2.0", ["https://raw.githubusercontent.com/hashicorp/vault/master/LICENSE"]],
        ["github.com/jessevdk/go-flags", "BSD-3-Clause", ["https://raw.githubusercontent.com/jessevdk/go-flags/master/LICENSE"]],
        ["github.com/jmespath/go-jmespath", "Apache-2.0", ["https://raw.githubusercontent.com/jmespath/go-jmespath/master/LICENSE"]],
        ["github.com/jonboulle/clockwork", "Apache-2.0", ["https://raw.githubusercontent.com/jonboulle/clockwork/master/LICENSE"]],
        ["github.com/lib/pq", "MIT", ["https://raw.githubusercontent.com/lib/pq/master/LICENSE.md"]],
        ["github.com/lib/pq/oid", "MIT", ["https://raw.githubusercontent.com/lib/pq/master/LICENSE.md"]],
        ["github.com/manucorporat/sse", "MIT", ["https://raw.githubusercontent.com/manucorporat/sse/master/LICENSE"]],
        ["github.com/mattn/go-colorable", "MIT", ["https://raw.githubusercontent.com/mattn/go-colorable/master/LICENSE"]],
        ["github.com/mattn/go-isatty", "MIT", ["https://raw.githubusercontent.com/mattn/go-isatty/master/LICENSE"]],
        ["github.com/mattn/go-sqlite3", "MIT", ["https://raw.githubusercontent.com/mattn/go-sqlite3/master/LICENSE"]],
        ["github.com/mitchellh/go-homedir", "MIT", ["https://raw.githubusercontent.com/mitchellh/go-homedir/master/LICENSE"]],
        ["github.com/mitchellh/mapstructure", "MIT", ["https://raw.githubusercontent.com/mitchellh/mapstructure/master/LICENSE"]],
        ["github.com/nu7hatch/gouuid", "MIT", ["https://raw.githubusercontent.com/nu7hatch/gouuid/master/COPYING"]],
        ["github.com/open-policy-agent/opa", "Apache-2.0", ["https://raw.githubusercontent.com/open-policy-agent/opa/master/LICENSE"]],
        ["github.com/patrickmn/go-cache", "MIT", ["https://raw.githubusercontent.com/patrickmn/go-cache/master/LICENSE"]],
        ["github.com/peterbourgon/mergemap", "BSD-2-Clause", ["https://raw.githubusercontent.com/peterbourgon/mergemap/master/LICENSE"]],
        ["github.com/philhofer/fwd", "MIT", ["https://raw.githubusercontent.com/philhofer/fwd/master/LICENSE.md"]],
        ["github.com/op/go-logging", "BSD-3-Clause", ["https://raw.githubusercontent.com/op/go-logging/master/LICENSE"]],
        ["github.com/pmylund/go-cache", "MIT", ["https://raw.githubusercontent.com/patrickmn/go-cache/master/LICENSE"]],
        ["github.com/sethgrid/pester", "MIT", ["https://raw.githubusercontent.com/sethgrid/pester/master/LICENSE.md"]],
        ["github.com/Sirupsen/logrus", "MIT", ["https://raw.githubusercontent.com/sirupsen/logrus/master/LICENSE"]],
        ["github.com/davecgh/go-spew", "ISC", ["https://raw.githubusercontent.com/davecgh/go-spew/master/LICENSE"]],
        ["github.com/gin-contrib/sse", "MIT", ["https://raw.githubusercontent.com/gin-contrib/sse/master/LICENSE"]],
        ["github.com/gocarina/gocsv", "MIT", ["https://raw.githubusercontent.com/gocarina/gocsv/master/LICENSE"]],
        ["github.com/pmezard/go-difflib", "BSD 3-clause", ["https://raw.githubusercontent.com/pmezard/go-difflib/master/LICENSE"]],
        ["github.com/stretchr/testify", "MIT", ["https://raw.githubusercontent.com/stretchr/testify/master/LICENSE"]],
        ["github.com/ugorji/go", "MIT", ["https://raw.githubusercontent.com/ugorji/go/master/LICENSE"]],
        ["github.com/tideland/golib", "BSD-3-Clause", ["https://raw.githubusercontent.com/tideland/golib/master/LICENSE"]],
        ["github.com/tinylib/msgp", "MIT", ["https://raw.githubusercontent.com/tinylib/msgp/master/LICENSE"]],
        ["golang.org/x/crypto", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/crypto/master/LICENSE"]],
        ["golang.org/x/crypto/pbkdf2", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/crypto/master/LICENSE"]],
        ["golang.org/x/crypto/scrypt", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/crypto/master/LICENSE"]],
        ["golang.org/x/crypto/ssh", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/crypto/master/LICENSE"]],
        ["golang.org/x/exp", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/exp/master/LICENSE"]],
        ["golang.org/x/net", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["golang.org/x/net/context", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["golang.org/x/net/netutil", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["golang.org/x/net/context", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["golang.org/x/sys", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/sys/master/LICENSE"]],
        ["golang.org/x/sys/unix", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/sys/master/LICENSE"]],
        ["gopkg.in/bluesuncorp/validator.v5", "MIT", ["https://raw.githubusercontent.com/go-playground/validator/v5/LICENSE"]],
        ["gopkg.in/gorp.v1", "MIT", ["https://raw.githubusercontent.com/go-gorp/gorp/v1.7.1/LICENSE"]],
        ["github.com/go-gorp/gorp", "MIT", ["https://raw.githubusercontent.com/go-gorp/gorp/master/LICENSE"]],
        ["gopkg.in/go-playground/validator.v8", "MIT", ["https://raw.githubusercontent.com/go-playground/validator/v8.18.1/LICENSE"]],
        ["gopkg.in/olivere/elastic.v3", "MIT", ["https://raw.githubusercontent.com/olivere/elastic/v3.0.68/LICENSE"]],
        ["gopkg.in/tylerb/graceful.v1", "MIT", ["https://raw.githubusercontent.com/tylerb/graceful/v1.2.13/LICENSE"]],
        ["gopkg.in/yaml.v2", "Apache-2.0", ["https://raw.githubusercontent.com/go-yaml/yaml/v2/LICENSE"]],
        ["gopkg.in/olivere/elastic.v5", "MIT", ["https://raw.githubusercontent.com/olivere/elastic/v5.0.41/LICENSE"]],
        ["github.com/pkg/errors", "BSD-2-Clause", ["https://raw.githubusercontent.com/pkg/errors/master/LICENSE"]],
        ["github.com/grpc-ecosystem/grpc-gateway", "BSD-3-Clause", ["https://raw.githubusercontent.com/grpc-ecosystem/grpc-gateway/master/LICENSE.txt"]],
        ["github.com/inconshreveable/mousetrap", "MIT", ["https://raw.githubusercontent.com/inconshreveable/mousetrap/master/LICENSE"]],
        ["github.com/spf13/cobra", "Apache-2.0", ["https://raw.githubusercontent.com/spf13/cobra/master/LICENSE.txt"]],
        ["github.com/spf13/pflag", "BSD-3-Clause", ["https://raw.githubusercontent.com/spf13/pflag/master/LICENSE"]],
        ["golang.org/x/text", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["google.golang.org/genproto", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["google.golang.org/grpc", "BSD-3-Clause", ["https://raw.githubusercontent.com/golang/net/master/LICENSE"]],
        ["github.com/schollz/closestmatch", "MIT", ["https://raw.githubusercontent.com/schollz/closestmatch/master/LICENSE"]],
        ["github.com/fsnotify/fsnotify", "BSD-3-Clause", ["https://raw.githubusercontent.com/fsnotify/fsnotify/master/LICENSE"]],
        ["github.com/magiconair/properties", "BSD-3-Clause", ["https://raw.githubusercontent.com/magiconair/properties/master/LICENSE"]],
        ["github.com/pelletier/go-toml", "MIT", ["https://raw.githubusercontent.com/pelletier/go-toml/master/LICENSE"]],
        ["github.com/sirupsen/logrus", "MIT", ["https://raw.githubusercontent.com/sirupsen/logrus/master/LICENSE"]],
        ["github.com/spf13/afero", "Apache-2.0", ["https://raw.githubusercontent.com/spf13/afero/master/LICENSE.txt"]],
        ["github.com/spf13/cast", "MIT", ["https://raw.githubusercontent.com/spf13/cast/master/LICENSE"]],
        ["github.com/spf13/jwalterweatherman", "MIT", ["https://raw.githubusercontent.com/spf13/jWalterWeatherman/master/LICENSE"]],
        ["github.com/spf13/viper", "MIT", ["https://raw.githubusercontent.com/spf13/viper/master/LICENSE"]],
        ["github.com/satori/go.uuid", "MIT", ["https://raw.githubusercontent.com/satori/go.uuid/master/LICENSE"]],
        ["github.com/teambition/rrule-go", "MIT", ["https://raw.githubusercontent.com/teambition/rrule-go/master/LICENSE"]],
      ].each do |override_data|
        override_license "go", override_data[0] do |version|
          {}.tap do |d|
            d[:license] = override_data[1] if override_data[1]
            d[:license_files] = override_data[2] if override_data[2]
          end
        end
      end
    end

  end
end
