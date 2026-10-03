# frozen_string_literal: true

require 'stringio'

RSpec.describe ToyRobot::CLI do
  let(:stdin) { StringIO.new }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  def run(*argv)
    described_class.new(argv: argv, stdin: stdin, stdout: stdout, stderr: stderr).run
  end

  it 'reads commands from a file given as the argument' do
    status = run(File.join(__dir__, '../../fixtures/scenario_a.txt'))

    expect(stdout.string).to eq("0,1,NORTH\n")
    expect(status).to eq(0)
  end

  it 'reads commands from standard input when no file is given' do
    stdin.string = "PLACE 0,0,NORTH\nLEFT\nREPORT\n"

    expect(run).to eq(0)
    expect(stdout.string).to eq("0,0,WEST\n")
  end

  it 'reports a missing file on stderr and exits 1' do
    expect(run('no/such/file.txt')).to eq(1)
    expect(stderr.string).to include('no/such/file.txt')
    expect(stdout.string).to eq('')
  end

  it 'rejects more than one file with usage on stderr and exits 1' do
    expect(run('a.txt', 'b.txt')).to eq(1)
    expect(stderr.string).to include('Usage:')
  end

  %w[-h --help].each do |flag|
    it "prints usage on stdout for #{flag} and exits 0" do
      expect(run(flag)).to eq(0)
      expect(stdout.string).to include('Usage:')
    end
  end
end
