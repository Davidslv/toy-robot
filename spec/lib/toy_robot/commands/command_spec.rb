# frozen_string_literal: true

RSpec.describe ToyRobot::Commands::Command do
  subject(:command) { described_class.new }

  it 'needs a placed robot by default' do
    expect(command.requires_robot?).to be(true)
  end

  it 'leaves #call to subclasses' do
    expect { command.call(nil, table: nil, output: nil) }.to raise_error(NotImplementedError, /Command#call/)
  end
end
