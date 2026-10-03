# frozen_string_literal: true

module ToyRobot
  module Commands
    # LEFT: rotate 90 degrees counter-clockwise without changing position.
    class Left < Command
      def call(robot, **)
        robot.turn_left
      end
    end
  end
end
