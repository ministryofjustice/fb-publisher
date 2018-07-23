require 'rails_helper'

describe ShellAdapter do
  describe 'add_pipe' do
    it 'joins the given cmd: and to: with a pipe' do
      expect(described_class.add_pipe(cmd: 'a', to: 'b')).to eq('a | b')
    end
  end

  describe '.add_redirect' do
    it 'joins the given cmd: and to: with a >>' do
      expect(described_class.add_redirect(cmd: 'a', to: 'b')).to eq('a >> b')
    end
  end

  describe '.build_cmd' do
    let(:executable) { 'myexe' }
    let(:args) { ['arg1', 'arg2'] }
    let(:redirect) { nil }
    let(:pipe) { nil }

    let(:result) do
      described_class.build_cmd(executable: executable,
                                args: args,
                                redirect_to: redirect,
                                pipe_to: pipe)
    end

    it 'joins the given executable and args with spaces' do
      expect(result).to eq('myexe arg1 arg2')
    end

    context 'given a redirect_to' do
      let(:redirect) { 'redirect.txt' }
      it 'adds the given redirect' do
        expect(result).to eq('myexe arg1 arg2 >> redirect.txt')
      end

      context 'and a pipe_to' do
        let(:pipe) { 'mypipe' }
        it 'adds the given pipe first' do
          expect(result).to eq('myexe arg1 arg2 | mypipe >> redirect.txt')
        end
      end
    end

    context 'given a pipe_to' do
      let(:pipe) { 'mypipe' }
      it 'adds the given pipe' do
        expect(result).to eq('myexe arg1 arg2 | mypipe')
      end
    end
  end


  describe '.exec' do
    let(:cmd_return) { 'ok' }
    before do
      allow(Kernel).to receive(:system).and_return(cmd_return)
    end

    it 'runs the given binary & arguments with Kernel.system' do
      expect(Kernel).to receive(:system).with('myexe arg1 arg2')
      described_class.exec('myexe', 'arg1', 'arg2')
    end

    context 'when the cmd returns something' do
      it 'does not raise an error' do
        expect { described_class.exec('myexe', 'arg1', 'arg2') }.to_not raise_error
      end
    end

    context 'when the cmd returns nil' do
      let(:cmd_return) { nil }
      it 'raises an error' do
        expect { described_class.exec('myexe', 'arg1', 'arg2') }.to raise_error(CmdFailedError)
      end
    end
  end

  describe 'capture_with_stdin' do
    let(:output) { 'output' }
    let(:success) { true }
    let(:exit_status) { double('status', success?: success) }
    let(:cmd) { ['myexe', 'arg1', 'arg2'] }
    let(:stdin) { 'some stuff' }
    before do
      allow(Open3).to receive(:capture2).and_return [output, exit_status]
    end
    it 'builds the command, passing the first arg as the executable' do
      expect(described_class).to receive(:build_cmd).with(executable: 'myexe', args: ['arg1', 'arg2'])
      described_class.capture_with_stdin( cmd: cmd, stdin: stdin)
    end

    it 'executes the built command line with Open3.capture2, passing the given stdin: as stdin_data:' do
      expect(Open3).to receive(:capture2).with('myexe arg1 arg2', stdin_data: stdin).and_return [output, exit_status]
      described_class.capture_with_stdin( cmd: cmd, stdin: stdin)
    end

    context 'when the cmd is a success' do
      let(:success) { true }
      it 'returns the stdout_str from the command' do
        expect(described_class.capture_with_stdin( cmd: cmd, stdin: stdin)).to eq(output)
      end
    end
    context 'when the cmd is not a success' do
      let(:success) { false }
      it 'raises a CmdFailedError' do
        expect{described_class.capture_with_stdin( cmd: cmd, stdin: stdin)}.to raise_error(CmdFailedError)
      end
    end
  end

  describe '.output_of' do
    let(:result) { 'result   ' }
    before do
      allow(described_class).to receive(:capture_with_stdin).and_return('result   ')
    end

    it 'calls capture_with_stdin, passing the given args as cmd:' do
      expect(described_class).to receive(:capture_with_stdin).with(cmd: ['any', 'thing']).and_return('result   ')
      described_class.output_of('any', 'thing')
    end

    it 'returns the result, with whitespace stripped' do
      expect(described_class.output_of('any', 'thing')).to eq('result')
    end
  end
end
