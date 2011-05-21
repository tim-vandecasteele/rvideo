# RVideo

  RVideo allows you to inspect and process video files.

## Install tools

  All you need is to install ffmpeg on your machine. We recommend Homebrew, a great package manager for OSX.
  (http://mxcl.github.com/homebrew)
  
    brew install ffmpeg

## File inspector

To inspect a file, initialize an RVideo file inspector object. See the 
documentation for details.

A few examples:

    file = RVideo::Inspector.new(:file => "#{APP_ROOT}/files/input.mp4")
  
    file = RVideo::Inspector.new(:raw_response => @existing_response)
  
    file = RVideo::Inspector.new(:file => "#{APP_ROOT}/files/input.mp4",
                                  :ffmpeg_binary => "#{APP_ROOT}/bin/ffmpeg")

    file.fps        # "29.97"
    file.duration   # "00:05:23.4"

## Transcoder 

To transcode a video, initialize a Transcoder object.

    transcoder = RVideo::Transcoder.new

Then pass a command and valid options to the execute method

    recipe = "ffmpeg -i $input_file$ -ar 22050 -ab 64 -f flv -r 29.97 -s"
    recipe += " $resolution$ -y $output_file$"
    recipe += "\nflvtool2 -U $output_file$"
    begin
      transcoder.execute(recipe, {:input_file => "/path/to/input.mp4",
        :output_file => "/path/to/output.flv", :resolution => "640x360"}) do |progress|
        puts "#{progress[:tool].tool_command}: #{progress[:progress]}%"
    rescue TranscoderError => e
      puts "Unable to transcode file: #{e.class} - #{e.message}"
    end

If the job succeeds, you can access the metadata of the input and output
files with:

    transcoder.original     # RVideo::Inspector object
    transcoder.processed    # RVideo::Inspector object

If the transcoding succeeds, the file may still have problems. RVideo
will populate an errors array if the duration of the processed video
differs from the duration of the original video, or if the processed
file is unreadable.

Progress is only reported for the ffmpeg tool at present, in future hopefully we'll see support extended for more tools.

There is also support for killing hung ffmpeg processes. We found that sometimes a bad file can cause ffmpeg to just stop processing but still sit there using 100% cpu. When monitoring the progress we spawn it off in a separate thread, and then monitor the progress in the main thread. If the ffmpeg process times out by not reporting progress for a specified amount of time, we kill it.

---

Thanks to Peter Boling and people from Zencoder for their work on RVideo.

Contribute to RVideo! If you want to help out, there are a few things you can 
do.

- Use, test, and submit bugs/patches
- Submit other fixes, features, optimizations, and refactorings
