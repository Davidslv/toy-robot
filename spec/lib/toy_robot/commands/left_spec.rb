# frozen_string_literal: true

RSpec.describe ToyRobot::Commands::Left do
  subject(:left) { described_class.new }

  let(:table) { ToyRobot::Table.new }

  it 'needs a placed robot' do
    expect(left.requires_robot?).to be(true)
  end

  it 'rotates the robot 90 degrees counter-clockwise without moving it' do
    expect(left.call(robot_at(2, 3, 'NORTH'), table: table, output: nil)).to eq(robot_at(2, 3, 'WEST'))
  end

  it 'works on the edge of the table, since turning never moves the robot' do
    expect(left.call(robot_at(0, 0, 'SOUTH'), table: table, output: nil)).to eq(robot_at(0, 0, 'EAST'))
  end
end
