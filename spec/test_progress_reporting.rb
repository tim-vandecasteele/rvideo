require File.dirname(__FILE__) + '/spec_helper'
require 'lib/rvideo'

FileUtils.mkdir_p TEMP_PATH

transcoder = RVideo::Transcoder.new

recipe = "ffmpeg -i $input_file$ -ar 22050 -ab 64 -f flv -y $output_file$"
recipe += "\nflvtool2 -U $output_file$"
begin
  transcoder.execute(recipe, {:input_file => spec_file("boat.avi"),
    :output_file => "#{TEMP_PATH}/output.flv", :progress => true}) do |tool, progress|
    puts "#{tool.tool_command}: #{progress}%"
  end
rescue RVideo::TranscoderError => e
  puts "Unable to transcode file: #{e.class} - #{e.message}"
end
