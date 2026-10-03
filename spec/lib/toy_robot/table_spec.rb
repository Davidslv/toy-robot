# frozen_string_literal: true

RSpec.describe ToyRobot::Table do
  describe '#contains?' do
    subject(:table) { described_class.new(width: 5, height: 5) }

    it 'contains every corner' do
      [[0, 0], [4, 0], [0, 4], [4, 4]].each do |x, y|
        expect(table.contains?(position(x, y))).to be(true), "expected (#{x},#{y}) on the table"
      end
    end

    it 'does not contain points just past any edge' do
      [[-1, 0], [0, -1], [5, 0], [0, 5]].each do |x, y|
        expect(table.contains?(position(x, y))).to be(false), "expected (#{x},#{y}) off the table"
      end
    end
  end

  it 'defaults to 5 x 5 units' do
    table = described_class.new

    expect(table.contains?(position(4, 4))).to be(true)
    expect(table.contains?(position(5, 5))).to be(false)
  end

  it 'supports other sizes' do
    table = described_class.new(width: 3, height: 7)

    expect(table.contains?(position(2, 6))).to be(true)
    expect(table.contains?(position(3, 6))).to be(false)
  end

  it 'rejects a size smaller than 1 x 1' do
    expect { described_class.new(width: 0, height: 5) }.to raise_error(ArgumentError, /width/)
    expect { described_class.new(width: 5, height: 0) }.to raise_error(ArgumentError, /height/)
  end
end
