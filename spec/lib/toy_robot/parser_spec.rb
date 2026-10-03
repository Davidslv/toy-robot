# frozen_string_literal: true

RSpec.describe ToyRobot::Parser do
  subject(:parser) { described_class.new }

  describe 'PLACE X,Y,F' do
    it 'builds a Place command with the position and heading' do
      command = parser.parse('PLACE 1,2,EAST')

      expect(command).to be_a(ToyRobot::Commands::Place)
      expect(command.position).to eq(position(1, 2))
      expect(command.direction).to eq(ToyRobot::Direction::EAST)
    end

    it 'accepts every heading' do
      %w[NORTH SOUTH EAST WEST].each do |heading|
        expect(parser.parse("PLACE 0,0,#{heading}").direction.to_s).to eq(heading)
      end
    end

    it 'accepts spaces after the commas' do
      expect(parser.parse('PLACE 1, 2, EAST').position).to eq(position(1, 2))
    end

    it 'parses negative and large coordinates so the table can reject them' do
      expect(parser.parse('PLACE -1,0,NORTH').position).to eq(position(-1, 0))
      expect(parser.parse('PLACE 99,0,NORTH').position).to eq(position(99, 0))
    end

    it 'reads numbers with leading zeros as decimal, not octal' do
      expect(parser.parse('PLACE 08,010,NORTH').position).to eq(position(8, 10))
    end

    [
      'PLACE',
      'PLACE 1,2',
      'PLACE 1,2,UP',
      'PLACE 1,2,north',
      'PLACE A,2,NORTH',
      'PLACE 1.5,2,NORTH',
      'PLACE 1,2,NORTH,EXTRA',
      'PLACE1,2,NORTH'
    ].each do |line|
      it "rejects #{line.inspect}" do
        expect(parser.parse(line)).to be_nil
      end
    end
  end

  {
    'MOVE' => ToyRobot::Commands::Move,
    'LEFT' => ToyRobot::Commands::Left,
    'RIGHT' => ToyRobot::Commands::Right,
    'REPORT' => ToyRobot::Commands::Report
  }.each do |line, command_class|
    it "parses #{line} into #{command_class}" do
      expect(parser.parse(line)).to be_a(command_class)
    end
  end

  it 'ignores whitespace around a command, including the line ending' do
    expect(parser.parse("  MOVE \n")).to be_a(ToyRobot::Commands::Move)
    expect(parser.parse("REPORT\r\n")).to be_a(ToyRobot::Commands::Report)
  end

  ['', '   ', 'JUMP', 'move', 'MOVE 2', 'MOVEMENT'].each do |line|
    it "returns nil for #{line.inspect}" do
      expect(parser.parse(line)).to be_nil
    end
  end
end
