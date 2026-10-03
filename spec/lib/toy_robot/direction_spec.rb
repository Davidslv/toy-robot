# frozen_string_literal: true

RSpec.describe ToyRobot::Direction do
  describe '.find' do
    it 'returns the direction with the given name' do
      expect(described_class.find('NORTH')).to eq(described_class::NORTH)
    end

    it 'returns nil for an unknown name' do
      expect(described_class.find('UP')).to be_nil
    end

    it 'is case sensitive, matching the brief' do
      expect(described_class.find('north')).to be_nil
    end
  end

  describe '#left' do
    {
      'NORTH' => 'WEST',
      'WEST' => 'SOUTH',
      'SOUTH' => 'EAST',
      'EAST' => 'NORTH'
    }.each do |from, to|
      it "turns #{from} counter-clockwise to #{to}" do
        expect(described_class.find(from).left).to eq(described_class.find(to))
      end
    end
  end

  describe '#right' do
    {
      'NORTH' => 'EAST',
      'EAST' => 'SOUTH',
      'SOUTH' => 'WEST',
      'WEST' => 'NORTH'
    }.each do |from, to|
      it "turns #{from} clockwise to #{to}" do
        expect(described_class.find(from).right).to eq(described_class.find(to))
      end
    end
  end

  describe 'one step forward' do
    # Origin (0,0) is the SOUTH-WEST corner, so NORTH increases y and EAST increases x.
    {
      'NORTH' => [0, 1],
      'EAST' => [1, 0],
      'SOUTH' => [0, -1],
      'WEST' => [-1, 0]
    }.each do |name, (dx, dy)|
      it "moves #{name} by (#{dx}, #{dy})" do
        direction = described_class.find(name)

        expect([direction.dx, direction.dy]).to eq([dx, dy])
      end
    end
  end

  describe '#to_s' do
    it 'is the name used in commands and reports' do
      expect(described_class::EAST.to_s).to eq('EAST')
    end
  end

  it 'is immutable' do
    expect(described_class::NORTH).to be_frozen
  end
end
