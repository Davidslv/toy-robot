# frozen_string_literal: true

require 'stringio'

RSpec.describe ToyRobot::Commands::Report do
  subject(:report) { described_class.new }

  let(:output) { StringIO.new }

  it 'needs a placed robot' do
    expect(report.requires_robot?).to be(true)
  end

  it 'writes X,Y,F and a newline to the output' do
    report.call(robot_at(3, 3, 'NORTH'), table: ToyRobot::Table.new, output: output)

    expect(output.string).to eq("3,3,NORTH\n")
  end

  it 'leaves the robot unchanged' do
    robot = robot_at(0, 1, 'WEST')

    expect(report.call(robot, table: ToyRobot::Table.new, output: output)).to eq(robot)
  end
end
