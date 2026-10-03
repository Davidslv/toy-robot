# frozen_string_literal: true

RSpec.describe ToyRobot::Commands::Move do
  subject(:move) { described_class.new }

  let(:table) { ToyRobot::Table.new(width: 5, height: 5) }

  def run(robot)
    move.call(robot, table: table, output: nil)
  end

  it 'needs a placed robot' do
    expect(move.requires_robot?).to be(true)
  end

  it 'moves the robot one unit in the direction it faces' do
    expect(run(robot_at(0, 0, 'NORTH'))).to eq(robot_at(0, 1, 'NORTH'))
    expect(run(robot_at(0, 0, 'EAST'))).to eq(robot_at(1, 0, 'EAST'))
    expect(run(robot_at(4, 4, 'SOUTH'))).to eq(robot_at(4, 3, 'SOUTH'))
    expect(run(robot_at(4, 4, 'WEST'))).to eq(robot_at(3, 4, 'WEST'))
  end

  it 'is ignored when it would take the robot off any edge' do
    [
      robot_at(2, 4, 'NORTH'),
      robot_at(4, 2, 'EAST'),
      robot_at(2, 0, 'SOUTH'),
      robot_at(0, 2, 'WEST')
    ].each do |robot|
      expect(run(robot)).to eq(robot)
    end
  end
end
