# frozen_string_literal: true

require 'open3'

# Runs the real executable, as a user would, against every input file in
# examples/ and compares standard output with the matching .expected file.
# To add a case, drop a NAME.txt and NAME.expected pair into examples/.
RSpec.describe 'bin/toy_robot', :acceptance do
  root = File.expand_path('../..', __dir__)
  executable = File.join(root, 'bin', 'toy_robot')
  inputs = Dir[File.join(root, 'examples', '*.txt')]

  it 'has examples to run' do
    expect(inputs).not_to be_empty
  end

  inputs.each do |input|
    name = File.basename(input, '.txt')
    expected = File.read(input.sub(/\.txt\z/, '.expected'))

    it "#{name} (file argument)" do
      stdout, stderr, status = Open3.capture3(RbConfig.ruby, executable, input)

      expect([stdout, stderr, status.exitstatus]).to eq([expected, '', 0])
    end

    it "#{name} (standard input)" do
      stdout, stderr, status = Open3.capture3(RbConfig.ruby, executable, stdin_data: File.read(input))

      expect([stdout, stderr, status.exitstatus]).to eq([expected, '', 0])
    end
  end
end
