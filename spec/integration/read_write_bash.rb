# frozen_string_literal: true

require_relative "../../lib/tools"

RSpec.describe "Write haiku to file and read it back" do
  it "generates haiku, writes to file, reads back, and verifies content, then uses bash to delete it" do
    haiku_tool = Crayons::Tools.new(:haiku)
    write_tool = Crayons::Tools.new(:write_file)
    read_tool = Crayons::Tools.new(:read_file)

    haiku_result = haiku_tool.call
    expect(haiku_result[:success]).to be true
    haiku_content = haiku_result[:result]

    write_result = write_tool.call(filepath: "haiku.txt", content: haiku_content)
    expect(write_result[:success]).to be true
    expect(write_result[:result][:bytes_written]).to eq(haiku_content.bytesize)

    read_result = read_tool.call(filepath: "haiku.txt")
    expect(read_result[:success]).to be true
    expect(read_result[:result][:content]).to eq(haiku_content)

    bash_tool = Crayons::Tools.new(:bash)
    bash_tool.call(command: "rm -f haiku.txt")
  end
end
