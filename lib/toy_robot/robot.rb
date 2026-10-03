# frozen_string_literal: true

module ToyRobot
  # The robot's state: where it stands and which way it faces.
  #
  # Every action returns a new Robot and leaves the receiver alone. A MOVE
  # can therefore build the robot it would become, ask the Table about it,
  # and drop it if the answer is no. Nothing needs undoing.
  #
  # The robot does not know about the table. Rules about where it may go
  # live in the commands that use the Table.
  Robot = Data.define(:position, :direction)

  class Robot
    def move
      with(position: position.step(direction))
    end

    def turn_left
      with(direction: direction.left)
    end

    def turn_right
      with(direction: direction.right)
    end

    def to_s
      "#{position},#{direction}"
    end
  end
end
