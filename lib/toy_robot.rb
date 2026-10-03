# frozen_string_literal: true

# Simulates a toy robot moving on a square table, driven by text commands.
# Each file below holds one concept; see README.md for how they fit together.
require_relative 'toy_robot/direction'
require_relative 'toy_robot/position'
require_relative 'toy_robot/robot'
require_relative 'toy_robot/table'
require_relative 'toy_robot/commands/command'
require_relative 'toy_robot/commands/place'
require_relative 'toy_robot/commands/move'
require_relative 'toy_robot/commands/left'
require_relative 'toy_robot/commands/right'
require_relative 'toy_robot/commands/report'
require_relative 'toy_robot/parser'
require_relative 'toy_robot/simulator'

module ToyRobot
end
