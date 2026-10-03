# frozen_string_literal: true

module ToyRobot
  # The command-line entry point: bin/toy_robot [FILE].
  #
  # Reads commands from FILE, or from standard input when no file is given,
  # and returns a process exit status. The streams are passed in instead of
  # using $stdin/$stdout directly, so the whole CLI can be tested in memory.
  class CLI
    USAGE = <<~TEXT
      Usage: toy_robot [FILE]

      Reads toy robot commands, one per line, from FILE or standard input.
      Commands: PLACE X,Y,F  MOVE  LEFT  RIGHT  REPORT
    TEXT

    def initialize(argv:, stdin:, stdout:, stderr:)
      @argv = argv
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
    end

    def run
      return usage(@stdout, status: 0) if help?
      return usage(@stderr, status: 1) if @argv.size > 1

      @argv.empty? ? simulate(@stdin) : simulate_file(@argv.first)
    end

    private

    def help?
      @argv.intersect?(%w[-h --help])
    end

    def simulate_file(path)
      File.open(path) { |file| simulate(file) }
    rescue SystemCallError => e
      @stderr.puts("toy_robot: cannot read #{path}: #{e.message}")
      1
    end

    def simulate(io)
      Simulator.new(output: @stdout).run(io.each_line)
      0
    end

    def usage(stream, status:)
      stream.puts(USAGE)
      status
    end
  end
end
