# frozen_string_literal: true

module ToyRobot
  # Turns one line of input into a command object, or nil if the line is
  # not a command this application understands.
  #
  # The parser checks syntax only. "PLACE 9,9,NORTH" parses fine even on a
  # 5 x 5 table; deciding that it is off the table is the Table's job. That
  # way each rule lives in exactly one class.
  #
  # Returning nil (instead of raising) lets the simulator skip bad lines
  # and carry on, which is what the brief asks for.
  class Parser
    PLACE = /\APLACE (?<x>-?\d+),\s*(?<y>-?\d+),\s*(?<facing>[A-Z]+)\z/

    SIMPLE_COMMANDS = {
      'MOVE' => Commands::Move,
      'LEFT' => Commands::Left,
      'RIGHT' => Commands::Right,
      'REPORT' => Commands::Report
    }.freeze

    def parse(line)
      text = line.strip
      SIMPLE_COMMANDS[text]&.new || parse_place(text)
    end

    private

    def parse_place(text)
      match = PLACE.match(text)
      direction = match && Direction.find(match[:facing])
      return unless direction

      Commands::Place.new(
        position: Position.new(x: Integer(match[:x], 10), y: Integer(match[:y], 10)),
        direction: direction
      )
    end
  end
end
