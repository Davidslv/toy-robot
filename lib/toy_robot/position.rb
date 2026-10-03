# frozen_string_literal: true

module ToyRobot
  # A point on the table grid, with (0,0) at the SOUTH-WEST corner.
  #
  # Position knows nothing about the table's size. It will happily step
  # to (0,-1); the Table decides whether a position is allowed. That split
  # keeps the "never fall off" rule in a single place.
  Position = Data.define(:x, :y)

  class Position
    def step(direction)
      with(x: x + direction.dx, y: y + direction.dy)
    end

    def to_s
      "#{x},#{y}"
    end
  end
end
