require "spec_helper"
require "logstash/runner"
require "stud/task"

class NullRunner
  def run(args); end
end

describe LogStash::Runner do

  subject { LogStash::Runner }

  describe "argument parsing" do

    context "when -e is given" do

      subject { LogStash::Runner.new("") }
      let(:args) { ["-e", ""] }

      it "should add an empty pipeline to the agent" do
        expect(subject.agent).to receive(:add_pipeline).once
        subject.run(args)
      end

      it "should execute the agent" do
        expect(subject.agent).to receive(:execute).once
        subject.run(args)
      end
    end

    context "when -h is given" do
      it "should run agent help" do
        #expect(subject).to receive(:show_help).once #.and_return(nil)
        args = ["-h"]
        expect(subject.run("", args)).to eq(0)
      end
    end

    context "with no arguments" do
      it "should show help with no arguments" do
        expect($stderr).to receive(:puts).once.and_return("No command given")
        expect($stderr).to receive(:puts).once
        args = []
        expect(subject.run("", args)).to eq(1)
      end
    end

    it "should show help for unknown commands" do
      #expect($stderr).to receive(:puts).once.and_return("No such command welp")
      expect($stderr).to receive(:puts).once
      args = ["welp"]
      expect(subject.run("", args)).to eq(1)
    end
  end

  context "when loading the configuration" do
    subject { LogStash::Runner.new("") }
    context "when local" do
      before { expect(subject).to receive(:local_config).with(path) }

      context "unix" do
        let(:path) { './test.conf' }
        it 'works with relative path' do
          subject.load_config(path)
        end
      end

      context "windows" do
        let(:path) { '.\test.conf' }
        it 'work with relative windows path' do
          subject.load_config(path)
        end
      end
    end

    context "when remote" do
      context 'supported scheme' do
        let(:path) { "http://test.local/superconfig.conf" }
        let(:dummy_config) { 'input {}' }

        before { expect(Net::HTTP).to receive(:get) { dummy_config } }
        it 'works with http' do
          expect(subject.load_config(path)).to eq("#{dummy_config}\n")
        end
      end
    end
  end

  context "--pluginpath" do
    subject { LogStash::Runner.new("") }
    let(:single_path) { "/some/path" }
    let(:multiple_paths) { ["/some/path1", "/some/path2"] }

    it "should add single valid dir path to the environment" do
      expect(File).to receive(:directory?).and_return(true)
      expect(LogStash::Environment).to receive(:add_plugin_path).with(single_path)
      subject.configure_plugin_paths(single_path)
    end

    it "should fail with single invalid dir path" do
      expect(File).to receive(:directory?).and_return(false)
      expect(LogStash::Environment).not_to receive(:add_plugin_path)
      expect{subject.configure_plugin_paths(single_path)}.to raise_error(LogStash::ConfigurationError)
    end

    it "should add multiple valid dir path to the environment" do
      expect(File).to receive(:directory?).exactly(multiple_paths.size).times.and_return(true)
      multiple_paths.each{|path| expect(LogStash::Environment).to receive(:add_plugin_path).with(path)}
      subject.configure_plugin_paths(multiple_paths)
    end
  end
end
