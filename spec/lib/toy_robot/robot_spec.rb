# frozen_string_literal: true

RSpec.describe ToyRobot::Robot do
  subject(:robot) { described_class.new(position: ToyRobot::Position.new(x: 1, y: 2), direction: ToyRobot::Direction::EAST) }

  describe '#move' do
    it 'returns a robot one step forward, facing the same way' do
      moved = robot.move

      expect(moved.position).to eq(ToyRobot::Position.new(x: 2, y: 2))
      expect(moved.direction).to eq(ToyRobot::Direction::EAST)
    end
  end

  describe '#turn_left' do
    it 'returns a robot facing counter-clockwise, in the same place' do
      turned = robot.turn_left

      expect(turned.direction).to eq(ToyRobot::Direction::NORTH)
      expect(turned.position).to eq(robot.position)
    end
  end

  describe '#turn_right' do
    it 'returns a robot facing clockwise, in the same place' do
      turned = robot.turn_right

      expect(turned.direction).to eq(ToyRobot::Direction::SOUTH)
      expect(turned.position).to eq(robot.position)
    end
  end

  it 'never changes in place' do
    robot.move
    robot.turn_left
    robot.turn_right

    expect(robot).to eq(described_class.new(position: ToyRobot::Position.new(x: 1, y: 2), direction: ToyRobot::Direction::EAST))
  end

  describe '#to_s' do
    it 'formats as X,Y,F, the REPORT format from the brief' do
      expect(robot.to_s).to eq('1,2,EAST')
    end
  end
end
