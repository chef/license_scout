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

module LicenseScout
  module LicenseFileAnalyzer
    Matcher = Struct.new(:regexp) do
      def self.from_template(template)
        from_text(template.content)
      end

      def self.from_text(text)
        from_regex(Text.compile_to_regex(text))
      end

      # an alias for Matcher.new, for uniformity of constructors
      def self.from_regex(regexp)
        new(regexp)
      end

      def matches_text?(text)
        !!(Text.normalize_punctuation(text) =~ regexp)
      end
    end
  end
end
