# frozen_string_literal: true

module ToyRobot
  # A compass direction the robot can face.
  #
  # Each direction knows the one-step offset for moving forward and its
  # neighbours when turning. Turning walks the CLOCKWISE list, so there is
  # no case statement to keep in sync when reading or changing the rules.
  #
  # The origin (0,0) is the SOUTH-WEST corner: NORTH increases y and EAST
  # increases x.
  Direction = Data.define(:name, :dx, :dy)

  class Direction
    NORTH = new(name: 'NORTH', dx: 0, dy: 1)
    EAST = new(name: 'EAST', dx: 1, dy: 0)
    SOUTH = new(name: 'SOUTH', dx: 0, dy: -1)
    WEST = new(name: 'WEST', dx: -1, dy: 0)

    CLOCKWISE = [NORTH, EAST, SOUTH, WEST].freeze

    def self.find(name)
      CLOCKWISE.find { |direction| direction.name == name }
    end

    def left
      turn(-1)
    end

    def right
      turn(1)
    end

    def to_s
      name
    end

    private

    def turn(quarter_turns)
      CLOCKWISE[(CLOCKWISE.index(self) + quarter_turns) % CLOCKWISE.size]
    end
  end
end
