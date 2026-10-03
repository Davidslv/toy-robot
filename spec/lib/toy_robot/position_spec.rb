# frozen_string_literal: true

RSpec.describe ToyRobot::Position do
  subject(:position) { described_class.new(x: 2, y: 3) }

  describe '#step' do
    it 'returns the neighbouring position in the given direction' do
      expect(position.step(ToyRobot::Direction::NORTH)).to eq(described_class.new(x: 2, y: 4))
      expect(position.step(ToyRobot::Direction::EAST)).to eq(described_class.new(x: 3, y: 3))
      expect(position.step(ToyRobot::Direction::SOUTH)).to eq(described_class.new(x: 2, y: 2))
      expect(position.step(ToyRobot::Direction::WEST)).to eq(described_class.new(x: 1, y: 3))
    end

    it 'leaves the original position unchanged' do
      position.step(ToyRobot::Direction::NORTH)

      expect(position).to eq(described_class.new(x: 2, y: 3))
    end

    it 'can step below zero; the table decides whether that is allowed' do
      origin = described_class.new(x: 0, y: 0)

      expect(origin.step(ToyRobot::Direction::SOUTH)).to eq(described_class.new(x: 0, y: -1))
    end
  end

  describe '#to_s' do
    it 'formats as x,y' do
      expect(position.to_s).to eq('2,3')
    end
  end
end
