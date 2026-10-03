# frozen_string_literal: true

require 'optparse'

module ToyRobot
  # The command-line entry point: bin/toy_robot [--size WIDTHxHEIGHT] [FILE].
  #
  # Reads commands from FILE, or from standard input when no file is given,
  # and returns a process exit status. The streams are passed in instead of
  # using $stdin/$stdout directly, so the whole CLI can be tested in memory.
  class CLI
    # Raised for any mistake in how the command was invoked.
    class UsageError < StandardError; end

    SIZE_FORMAT = /\A(?<width>\d+)x(?<height>\d+)\z/

    # Exit status after Ctrl-C: 128 + 2 (SIGINT), the shell convention.
    INTERRUPTED = 130

    def initialize(argv:, stdin:, stdout:, stderr:)
      @argv = argv
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @table = Table.new
      @help = false
    end

    def run
      files = options.parse(@argv)
      return usage(@stdout, status: 0) if @help
      raise UsageError, 'expected at most one FILE' if files.size > 1

      files.empty? ? simulate(@stdin) : simulate_file(files.first)
    rescue OptionParser::ParseError, UsageError => e
      @stderr.puts("toy_robot: #{e.message}")
      usage(@stderr, status: 1)
    rescue Interrupt
      # Ctrl-C: stop quietly. The newline keeps the shell prompt off the ^C line.
      @stderr.puts
      INTERRUPTED
    end

    private

    def options
      @options ||= OptionParser.new do |parser|
        parser.banner = 'Usage: toy_robot [--size WIDTHxHEIGHT] [FILE]'
        parser.separator('')
        parser.separator('Reads toy robot commands, one per line, from FILE or standard input.')
        parser.separator('Commands: PLACE X,Y,F  MOVE  LEFT  RIGHT  REPORT')
        parser.separator('')
        parser.on('-s', '--size WIDTHxHEIGHT', 'Table size (default 5x5)') { |value| @table = build_table(value) }
        parser.on('-h', '--help', 'Show this help') { @help = true }
      end
    end

    def build_table(value)
      match = SIZE_FORMAT.match(value)
      raise UsageError, "invalid --size #{value.inspect}: expected WIDTHxHEIGHT, e.g. 5x5" unless match

      Table.new(width: Integer(match[:width], 10), height: Integer(match[:height], 10))
    rescue ArgumentError => e
      raise UsageError, "invalid --size #{value.inspect}: #{e.message}"
    end

    def simulate_file(path)
      File.open(path) { |file| simulate(file) }
    rescue SystemCallError => e
      @stderr.puts("toy_robot: cannot read #{path}: #{e.message}")
      1
    end

    def simulate(io)
      Simulator.new(output: @stdout, table: @table).run(io.each_line)
      0
    end

    def usage(stream, status:)
      stream.puts(options)
      status
    end
  end
end
