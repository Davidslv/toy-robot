# frozen_string_literal: true

module ToyRobot
  module Commands
    # PLACE X,Y,F: put the robot on the table, or move it there if it is
    # already placed. A position off the table is ignored, so the robot can
    # never start off the edge.
    class Place < Command
      attr_reader :position, :direction

      def initialize(position:, direction:)
        super()
        @position = position
        @direction = direction
      end

      def requires_robot?
        false
      end

      def call(robot, table:, **)
        return robot unless table.contains?(position)

        Robot.new(position: position, direction: direction)
      end
    end
  end
end
