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

require "open-uri"
require "tmpdir"
require "digest"

require "license_scout/exceptions"

module LicenseScout
  class NetFetcher

    attr_reader :from_url

    def initialize(from_url)
      @from_url = from_url
    end

    def fetch!
      download_file! unless exists_in_cache?
    end

    def cache_dir
      File.join(Dir.tmpdir, "license_scout_cache")
    end

    def cache_path
      File.join(cache_dir, url_cache_key, File.basename(from_url))
    end

    private

    def exists_in_cache?
      File.exist?(cache_path)
    end

    def url_cache_key
      d = Digest::SHA256.new
      d.update(from_url)
      d.hexdigest
    end

    def save_to_cache(file)
      cache_directory = File.dirname(cache_path)
      FileUtils.mkdir_p(cache_directory) unless File.exist?(cache_directory)

      File.open(cache_path, "w+") do |output_file|
        output_file.print(file.read)
      end
    end

    # This method is highly inspired from:
    # https://github.com/chef/omnibus/blob/master/lib/omnibus/download_helpers.rb
    def download_file!
      retries = 3

      begin
        options = {
          :read_timeout => 60,
        }

        open(from_url, options) do |f|
          save_to_cache(f)
        end
      rescue SocketError,
             Errno::ECONNREFUSED,
             Errno::ECONNRESET,
             Errno::ENETUNREACH,
             Timeout::Error,
             OpenURI::HTTPError => e
        if retries != 0
          retries -= 1
          retry
        else
          raise Exceptions::NetworkError.new(from_url, e)
        end
      end
    end
  end
end
