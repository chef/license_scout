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
    module Text
      SPACES = /[[:space:]]+/
      QUOTES = /['`"]{1,2}/
      PLACEHOLDERS = /<[^<>]+>/

      def self.normalize_punctuation(text)
        text.gsub(SPACES, ' ')
            .gsub(QUOTES, '"')
            .strip
      end

      def self.compile_to_regex(text)
        text = normalize_punctuation(text)
        regex_source = Regexp.escape(text)
        regex_source = regex_source.gsub(PLACEHOLDERS, '(.*)')
        Regexp.new(regex_source, Regexp::IGNORECASE)
      end
    end
  end
end

