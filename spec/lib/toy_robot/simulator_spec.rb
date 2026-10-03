# frozen_string_literal: true

require 'stringio'

RSpec.describe ToyRobot::Simulator do
  let(:output) { StringIO.new }

  def run(*lines)
    described_class.new(output: output).run(lines)
    output.string
  end

  describe 'the example scenarios from the brief' do
    it 'A: basic movement' do
      expect(run('PLACE 0,0,NORTH', 'MOVE', 'REPORT')).to eq("0,1,NORTH\n")
    end

    it 'B: rotation' do
      expect(run('PLACE 0,0,NORTH', 'LEFT', 'REPORT')).to eq("0,0,WEST\n")
    end

    it 'C: complex sequence' do
      expect(run('PLACE 1,2,EAST', 'MOVE', 'MOVE', 'LEFT', 'MOVE', 'REPORT')).to eq("3,3,NORTH\n")
    end
  end

  describe 'before the first valid PLACE' do
    it 'discards every command' do
      expect(run('MOVE', 'LEFT', 'RIGHT', 'REPORT')).to eq('')
    end

    it 'discards commands that come before the PLACE, then obeys the rest' do
      expect(run('MOVE', 'REPORT', 'PLACE 1,1,NORTH', 'MOVE', 'REPORT')).to eq("1,2,NORTH\n")
    end

    it 'keeps discarding after a PLACE that is off the table' do
      expect(run('PLACE 5,5,NORTH', 'MOVE', 'REPORT', 'PLACE 0,0,EAST', 'REPORT')).to eq("0,0,EAST\n")
    end
  end

  describe 'once placed' do
    it 'ignores a MOVE that would fall off, and keeps going' do
      expect(run('PLACE 0,4,NORTH', 'MOVE', 'REPORT', 'RIGHT', 'MOVE', 'REPORT')).to eq("0,4,NORTH\n1,4,EAST\n")
    end

    it 'cannot be walked off any edge, however many moves' do
      lines = ['PLACE 2,2,WEST'] + (['MOVE'] * 10) + ['REPORT']

      expect(run(*lines)).to eq("0,2,WEST\n")
    end

    it 'accepts another PLACE, which moves the robot' do
      expect(run('PLACE 0,0,NORTH', 'PLACE 3,1,SOUTH', 'REPORT')).to eq("3,1,SOUTH\n")
    end

    it 'ignores a later PLACE that is off the table' do
      expect(run('PLACE 2,2,EAST', 'PLACE -1,2,EAST', 'REPORT')).to eq("2,2,EAST\n")
    end

    it 'reports as many times as asked' do
      expect(run('PLACE 0,0,NORTH', 'REPORT', 'MOVE', 'REPORT')).to eq("0,0,NORTH\n0,1,NORTH\n")
    end

    it 'turns all the way round in both directions' do
      expect(run('PLACE 1,1,NORTH', 'LEFT', 'LEFT', 'LEFT', 'LEFT', 'REPORT',
                 'RIGHT', 'RIGHT', 'RIGHT', 'RIGHT', 'REPORT')).to eq("1,1,NORTH\n1,1,NORTH\n")
    end
  end

  it 'skips lines that are not commands' do
    expect(run('', 'PLACE 0,0,NORTH', 'JUMP', 'move', 'MOVE', 'REPORT')).to eq("0,1,NORTH\n")
  end

  it 'uses the table it is given' do
    simulator = described_class.new(table: ToyRobot::Table.new(width: 2, height: 2), output: output)
    simulator.run(['PLACE 1,1,NORTH', 'MOVE', 'REPORT', 'PLACE 2,2,NORTH', 'REPORT'])

    expect(output.string).to eq("1,1,NORTH\n1,1,NORTH\n")
  end

  it 'exposes the robot after the run, or nil if it was never placed' do
    expect(described_class.new(output: output).run(['PLACE 4,4,WEST']).robot).to eq(robot_at(4, 4, 'WEST'))
    expect(described_class.new(output: output).run(['MOVE']).robot).to be_nil
  end

  it 'reads from anything that yields lines, such as an IO' do
    described_class.new(output: output).run(StringIO.new("PLACE 0,0,NORTH\nMOVE\nREPORT\n").each_line)

    expect(output.string).to eq("0,1,NORTH\n")
  end
end
