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
    # Matches "PLACE X,Y,F", e.g. "PLACE 1,2,EAST" or "PLACE 1, 2, EAST".
    # The x flag ignores whitespace in the pattern and allows comments, so a
    # literal space has to be written as [ ].
    PLACE = /
      \A                    # start of the line
      PLACE[ ]              # the keyword and exactly one space
      (?<x>-?\d+)           # x: whole number, may be negative (the table rejects it later)
      ,\s*                  # comma, optional spaces
      (?<y>-?\d+)           # y: same as x
      ,\s*                  # comma, optional spaces
      (?<facing>[A-Z]+)     # heading in capitals; Direction.find checks it is a real one
      \z                    # end of the line, nothing extra allowed
    /x

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
