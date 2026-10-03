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
    status = run(File.expand_path('../../../examples/a_basic_movement.txt', __dir__))

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

  it 'lists the --size option in the usage' do
    run('--help')

    expect(stdout.string).to include('--size WIDTHxHEIGHT')
  end

  describe '--size' do
    before { stdin.string = "PLACE 6,2,NORTH\nREPORT\nPLACE 0,0,NORTH\nMOVE\nMOVE\nMOVE\nREPORT\n" }

    it 'defaults to a 5 x 5 table' do
      expect(run).to eq(0)
      expect(stdout.string).to eq("0,3,NORTH\n")
    end

    it 'sets the table width and height' do
      expect(run('--size', '7x3')).to eq(0)
      expect(stdout.string).to eq("6,2,NORTH\n0,2,NORTH\n")
    end

    it 'accepts the --size=WxH form' do
      expect(run('--size=7x3')).to eq(0)
      expect(stdout.string).to eq("6,2,NORTH\n0,2,NORTH\n")
    end

    it 'accepts the -s short form' do
      expect(run('-s', '7x3')).to eq(0)
      expect(stdout.string).to eq("6,2,NORTH\n0,2,NORTH\n")
    end

    it 'works together with a file argument, in either order' do
      file = File.expand_path('../../../examples/a_basic_movement.txt', __dir__)

      expect(run('--size', '1x2', file)).to eq(0)
      expect(run(file, '--size', '1x2')).to eq(0)
      expect(stdout.string).to eq("0,1,NORTH\n" * 2)
    end

    ['5', 'x5', '5x', '5x5x5', '-1x5', 'axb', '5 x 5', ''].each do |value|
      it "rejects #{value.inspect} with an error on stderr and exits 1" do
        expect(run('--size', value)).to eq(1)
        expect(stderr.string).to include('invalid --size').and include('Usage:')
        expect(stdout.string).to eq('')
      end
    end

    it 'rejects a zero dimension, explaining why' do
      expect(run('--size', '0x5')).to eq(1)
      expect(stderr.string).to include('width must be at least 1')
    end

    it 'rejects --size with no value' do
      expect(run('--size')).to eq(1)
      expect(stderr.string).to include('missing argument: --size')
    end
  end

  it 'rejects an unknown option with usage on stderr and exits 1' do
    expect(run('--speed', '2')).to eq(1)
    expect(stderr.string).to include('invalid option: --speed').and include('Usage:')
  end
end
