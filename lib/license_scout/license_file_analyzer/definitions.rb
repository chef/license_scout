# Copied from https://github.com/pivotal/LicenseFinder
#
# The MIT License
#
# Copyright (c) 2012 Pivotal Labs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require "license_scout/license_file_analyzer/matcher"
require "license_scout/license_file_analyzer/any_matcher"
require "license_scout/license_file_analyzer/header_matcher"
require "license_scout/license_file_analyzer/template"

module LicenseScout
  module LicenseFileAnalyzer

    class License

      attr_reader :matcher
      attr_reader :short_name

      def initialize(short_name:, matcher: nil)
        @short_name  = short_name
        @matcher     = matcher || Matcher.from_template(Template.named(short_name))
      end

      def matches_text?(text)
        matcher.matches_text?(text)
      end

    end

    module Definitions
      extend self

      def all
        [
          apache2,
          bsd,
          gplv2,
          gplv3,
          isc,
          lgpl,
          mit,
          mpl2,
          bsd_3_clause,
          python,
          ruby,
          bsd_2_clause,
          erlang_public,
        ]
      end

      private

      def apache2
        matcher = AnyMatcher.new(
          Matcher.from_template(Template.named("Apache2")),
          Matcher.from_template(Template.named("Apache2-short"))
        )

        License.new(
          short_name:  "Apache-2.0",
          matcher:     matcher
        )
      end

      def bsd
        License.new(
          short_name:  "BSD"
        )
      end

      def gplv2
        License.new(
          short_name:  "GPL-2.0"
        )
      end

      def gplv3
        License.new(
          short_name:  "GPL-3.0"
        )
      end

      def isc
        License.new(
          short_name: "ISC"
        )
      end

      def lgpl
        License.new(
          short_name: "LGPL-3.0"
        )
      end

      def mit
        url_regexp = %r{MIT Licen[sc]e.*http://(?:www\.)?opensource\.org/licenses/mit-license}
        header_regexp = /The MIT Licen[sc]e/
        one_liner_regexp = /is released under the MIT licen[sc]e/

        matcher = AnyMatcher.new(
          Matcher.from_template(Template.named("MIT")),
          Matcher.from_regex(url_regexp),
          HeaderMatcher.new(Matcher.from_regex(header_regexp)),
          Matcher.from_regex(one_liner_regexp)
        )

        License.new(
          short_name:  "MIT",
          matcher:     matcher
        )
      end

      def mpl2
        header_regexp = /Mozilla Public Licen[sc]e, version 2.0/

        matcher = AnyMatcher.new(
          Matcher.from_template(Template.named("MPL2")),
          HeaderMatcher.new(Matcher.from_regex(header_regexp))
        )

        License.new(
          short_name:  "MPL-2.0",
          matcher:     matcher
        )
      end

      def bsd_3_clause
        substitution = [
          "Neither the name of <organization> nor the names of <possessive> contributors may be used to endorse or promote products derived from this software without specific prior written permission.",
          "The names of its contributors may not be used to endorse or promote products derived from this software without specific prior written permission.",
        ]

        template = Template.named("BSD-3-Clause")
        alternate_content = template.content.gsub(*substitution)

        alt_format_template = Template.named("BSD-3-Clause-alt-format")
        alt_format_with_alt_content = alt_format_template.content.gsub(*substitution)

        matcher = AnyMatcher.new(
          Matcher.from_template(template),
          Matcher.from_text(alternate_content),
          Matcher.from_template(alt_format_template),
          Matcher.from_text(alt_format_with_alt_content)
        )

        License.new(
          short_name:  "BSD-3-Clause",
          matcher:     matcher
        )
      end

      def python
        License.new(
          short_name:  "Python-2.0"
        )
      end

      def ruby
        url = "http://www.ruby-lang.org/en/LICENSE.txt"

        matcher = AnyMatcher.new(
          Matcher.from_template(Template.named("Ruby")),
          Matcher.from_text(url)
        )

        License.new(
          short_name:  "Ruby",
          matcher:     matcher
        )
      end

      def bsd_2_clause
        matcher = AnyMatcher.new(
          Matcher.from_template(Template.named("BSD-2-Clause")),
          Matcher.from_template(Template.named("BSD-2-Clause-bullets"))
        )

        License.new(
          short_name:  "BSD-2-Clause",
          matcher:     matcher
        )
      end

      def erlang_public
        License.new(
          short_name: "Erlang-Public",
          matcher:    Matcher.from_template(Template.named("EPLICENSE"))
        )
      end

    end
  end
end
