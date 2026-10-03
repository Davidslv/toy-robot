# frozen_string_literal: true

module ToyRobot
  # Runs a sequence of text commands against one robot on one table.
  #
  # The simulator does not interpret commands itself: the Parser reads each
  # line, and each command decides what it does. The simulator owns one
  # rule only: commands that need a robot are discarded until a valid
  # PLACE has put one on the table.
  #
  # The table, output and parser are passed in, so tests can use a
  # StringIO or a different table size without touching this class.
  class Simulator
    attr_reader :robot

    def initialize(output:, table: Table.new, parser: Parser.new)
      @output = output
      @table = table
      @parser = parser
      @robot = nil
    end

    # lines: anything that responds to #each and yields strings, such as an
    # Array, a File or $stdin. Returns self so callers can inspect #robot.
    def run(lines)
      lines.each { |line| execute(@parser.parse(line)) }
      self
    end

    private

    def execute(command)
      return if command.nil?
      return if command.requires_robot? && robot.nil?

      @robot = command.call(robot, table: @table, output: @output)
    end
  end
end
