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

RSpec.describe LicenseScout::DependencyManager::Rebar do

  let(:subject) { described_class.new(directory) }
  let(:directory) { "/some/random/directory" }

  let(:rebar_config_path) { File.join(directory, "rebar.config") }

  describe ".new" do
    it "creates new instance of a dependency manager" do
      expect(subject.directory).to eql(directory)
    end
  end

  describe "#name" do
    it "equals 'erlang_rebar'" do
      expect(subject.name).to eql("erlang_rebar")
    end
  end

  describe "#type" do
    it "equals 'erlang'" do
      expect(subject.type).to eql("erlang")
    end
  end

  describe "#signature" do
    it "equals 'rebar.config file'" do
      expect(subject.signature).to eql("rebar.config file")
    end
  end

  describe "#install_command" do
    it "returns 'rebar get-deps'" do
      expect(subject.install_command).to eql("rebar get-deps")
    end
  end

  describe "#detected?" do
    let(:rebar_config_exists) { true }

    before do
      expect(File).to receive(:exist?).with(rebar_config_path).and_return(rebar_config_exists)
    end

    context "when rebar.config exists" do
      it "returns true" do
        expect(subject.detected?).to be true
      end
    end

    context "when rebar.config is missing" do
      let(:rebar_config_exists) { false }

      it "returns false" do
        expect(subject.detected?).to be false
      end
    end
  end

  describe "#dependencies" do
    let(:subject) { described_class.new(directory) }
    let(:directory) { "/fake/project" }
    let(:project_deps_dir) { "/fake/project/_build/default/lib" }

    before do
      allow(subject).to receive(:project_deps_dir).and_return(project_deps_dir)
      allow(LicenseScout::Log).to receive(:warn)
      allow(subject).to receive(:parse_rebar_config)
    end

    context "when @rebar_deps is nil" do
      before do
        subject.instance_variable_set(:@rebar_deps, nil)
        allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
      end

      it "returns an empty array" do
        expect(subject.dependencies).to eq([])
      end
    end

    context "when @rebar_deps is present" do
      let(:rebar_deps) do
        {
          "dep1" => { source: "dep1_source", version: "1.0.0" },
          "dep2" => { source: "dep2_source", version: "2.0.0" }
        }
      end

      before do
        subject.instance_variable_set(:@rebar_deps, rebar_deps)
        allow(Open3).to receive(:capture3).with("rebar3 get-deps").and_return(["", "", double(success?: true)])
      end

      context "when all dependency directories exist" do
        before do
          allow(File).to receive(:exist?).with(File.join(project_deps_dir, "dep1")).and_return(true)
          allow(File).to receive(:exist?).with(File.join(project_deps_dir, "dep2")).and_return(true)
          allow(subject).to receive(:new_dependency) do |name, version, path|
            double(name: name, version: version, path: path)
          end
        end

        it "returns an array of dependency objects" do
          deps = subject.dependencies
          expect(deps.size).to eq(2)
          expect(deps.map(&:name)).to contain_exactly("dep1_source", "dep2_source")
          expect(deps.map(&:version)).to contain_exactly("1.0.0", "2.0.0")
        end
      end

      context "when some dependency directories do not exist" do
        before do
          allow(File).to receive(:exist?).with(File.join(project_deps_dir, "dep1")).and_return(true)
          allow(File).to receive(:exist?).with(File.join(project_deps_dir, "dep2")).and_return(false)
          allow(subject).to receive(:new_dependency) do |name, version, path|
            double(name: name, version: version, path: path)
          end
        end

        it "skips missing dependency directories" do
          deps = subject.dependencies
          expect(deps.size).to eq(1)
          expect(deps.first.name).to eq("dep1_source")
        end

        it "logs a warning for missing dependency directories" do
          subject.dependencies
          expect(LicenseScout::Log).to have_received(:warn).with(/\[rebar\] Dependency directory not found:/)
        end
      end

      context "when Open3.capture3 fails" do
        before do
          allow(Open3).to receive(:capture3).with("rebar3 get-deps").and_return(["", "error message", double(success?: false)])
          allow(File).to receive(:exist?).and_return(true)
          allow(subject).to receive(:new_dependency) do |name, version, path|
            double(name: name, version: version, path: path)
          end
        end

        it "still returns dependencies but logs error" do
          expect { subject.dependencies }.to output(/Failed to download dependencies/).to_stdout
        end
      end
    end
  end
end
