# frozen_string_literal: true

# Short builders so specs read like the brief: robot_at(1, 2, 'EAST').
module RobotHelpers
  def position(x, y)
    ToyRobot::Position.new(x: x, y: y)
  end

  def robot_at(x, y, facing)
    ToyRobot::Robot.new(position: position(x, y), direction: ToyRobot::Direction.find(facing))
  end
end

RSpec.configure do |config|
  config.include RobotHelpers
end
