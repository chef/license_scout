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

require "license_scout/net_fetcher"

RSpec.describe(LicenseScout::NetFetcher) do

  let(:tmpdir) { Dir.mktmpdir }

  before do
    FileUtils.rm_rf(fetcher.cache_dir)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  subject(:fetcher) { described_class.new(url) }

  let(:url) { "https://chef-license-spec.s3.amazonaws.com/README" }
  let(:expected_download_content) {
    <<-EOS
This folder and file is being used for testing by the following project:

https://github.com/chef/license_scout

Please do not delete!
EOS
  }

  let(:expected_cache_path) { fetcher.cache_path }

  it "has a cache directory and cache path" do
    expect(fetcher.cache_dir).to be_a(String)
    expect(fetcher.cache_path).to end_with(File.basename(url))
  end

  describe "when the file on the internet is accessible" do

    it "puts the file in the cache" do
      fetcher.fetch!
      expect(File).to exist(expected_cache_path)
      expect(File.read(expected_cache_path)).to eq(expected_download_content)
    end

    context "when the cache already contains the file" do

      before do
        FileUtils.mkdir_p(File.dirname(fetcher.cache_path))
        FileUtils.touch(fetcher.cache_path)
      end

      it "picks the cache from the file" do
        expect(fetcher).not_to receive(:open)
        fetcher.fetch!
      end
    end

  end

  describe "when the file on the internet is not accessible" do

    let(:success_after_count) { 5 }

    before do
      @call_count = 0
      original_open = fetcher.method(:open)

      allow(fetcher).to receive(:open) do |url, options, &block|
        if @call_count == success_after_count
          original_open.call(url, options, &block)
        else
          @call_count += 1
          raise Errno::ENETUNREACH.new
        end
      end
    end

    it "raises an error after 3 retries" do
      expect { fetcher.fetch! }.to raise_error(LicenseScout::Exceptions::NetworkError)
      # open will be called 4 times in total, first call + 3 retries
      expect(@call_count).to eq(4)
    end

    context "when the error is temporary" do
      let(:success_after_count) { 2 }

      it "fetches the file" do
        fetcher.fetch!
        expect(File).to exist(expected_cache_path)
        expect(File.read(expected_cache_path)).to eq(expected_download_content)
      end
    end
  end

end
