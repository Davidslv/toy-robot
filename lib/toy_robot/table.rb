# frozen_string_literal: true

module ToyRobot
  # The rectangular surface the robot stands on.
  #
  # This is the only place that knows the edges. PLACE and MOVE both ask
  # #contains? before committing to a new position, which is how the robot
  # never falls off.
  class Table
    DEFAULT_SIZE = 5

    def initialize(width: DEFAULT_SIZE, height: DEFAULT_SIZE)
      raise ArgumentError, "width must be at least 1, got #{width}" if width < 1
      raise ArgumentError, "height must be at least 1, got #{height}" if height < 1

      @x_range = 0...width
      @y_range = 0...height
      freeze
    end

    def contains?(position)
      @x_range.cover?(position.x) && @y_range.cover?(position.y)
    end
  end
end
