# frozen_string_literal: true

module ToyRobot
  module Commands
    # The interface every command implements.
    #
    # #call takes the current robot (nil until a valid PLACE) and returns
    # the robot that should exist afterwards. Returning the same robot means
    # "ignored". Commands receive the table and the output as keyword
    # arguments and use only the ones they need.
    #
    # To add a command: subclass this, implement #call, and teach the Parser
    # its syntax. Nothing else changes.
    class Command
      # Whether the command can only run once the robot is on the table.
      # The brief says everything before the first valid PLACE is discarded.
      def requires_robot?
        true
      end

      def call(_robot, table:, output:)
        raise NotImplementedError, "#{self.class}#call is not implemented"
      end
    end
  end
end
