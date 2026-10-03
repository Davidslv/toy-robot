# frozen_string_literal: true

module ToyRobot
  module Commands
    # REPORT: write the robot's X,Y,F to the output, one line per report.
    class Report < Command
      def call(robot, output:, **)
        output.puts(robot)
        robot
      end
    end
  end
end
