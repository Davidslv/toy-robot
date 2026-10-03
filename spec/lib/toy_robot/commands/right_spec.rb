# frozen_string_literal: true

RSpec.describe ToyRobot::Commands::Right do
  subject(:right) { described_class.new }

  let(:table) { ToyRobot::Table.new }

  it 'needs a placed robot' do
    expect(right.requires_robot?).to be(true)
  end

  it 'rotates the robot 90 degrees clockwise without moving it' do
    expect(right.call(robot_at(2, 3, 'NORTH'), table: table, output: nil)).to eq(robot_at(2, 3, 'EAST'))
  end

  it 'works on the edge of the table, since turning never moves the robot' do
    expect(right.call(robot_at(4, 4, 'EAST'), table: table, output: nil)).to eq(robot_at(4, 4, 'SOUTH'))
  end
end
