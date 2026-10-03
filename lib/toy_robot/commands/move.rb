# frozen_string_literal: true

module ToyRobot
  module Commands
    # MOVE: one unit forward in the direction the robot faces. A move that
    # would leave the table is ignored.
    class Move < Command
      def call(robot, table:, **)
        moved = robot.move
        table.contains?(moved.position) ? moved : robot
      end
    end
  end
end
