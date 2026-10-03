# frozen_string_literal: true

module ToyRobot
  module Commands
    # RIGHT: rotate 90 degrees clockwise without changing position.
    class Right < Command
      def call(robot, **)
        robot.turn_right
      end
    end
  end
end
