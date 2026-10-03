# frozen_string_literal: true

RSpec.describe ToyRobot::Commands::Place do
  let(:table) { ToyRobot::Table.new(width: 5, height: 5) }

  def place(x, y, facing, robot: nil)
    described_class.new(position: position(x, y), direction: ToyRobot::Direction.find(facing))
                   .call(robot, table: table, output: nil)
  end

  it 'can run before the robot is on the table' do
    expect(described_class.new(position: position(0, 0), direction: ToyRobot::Direction::NORTH).requires_robot?).to be(false)
  end

  it 'puts the robot on the table at the given position and heading' do
    expect(place(1, 2, 'EAST')).to eq(robot_at(1, 2, 'EAST'))
  end

  it 'accepts every corner of the table' do
    expect(place(0, 0, 'NORTH')).to eq(robot_at(0, 0, 'NORTH'))
    expect(place(4, 4, 'SOUTH')).to eq(robot_at(4, 4, 'SOUTH'))
  end

  it 'is ignored when the position is off the table and the robot is not yet placed' do
    expect(place(5, 0, 'NORTH')).to be_nil
  end

  it 'is ignored when the position is off the table, leaving a placed robot where it was' do
    existing = robot_at(2, 2, 'WEST')

    expect(place(-1, 3, 'NORTH', robot: existing)).to eq(existing)
  end

  it 'moves an already placed robot when given a valid position' do
    expect(place(3, 3, 'SOUTH', robot: robot_at(0, 0, 'NORTH'))).to eq(robot_at(3, 3, 'SOUTH'))
  end
end
