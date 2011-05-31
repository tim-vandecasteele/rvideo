module RVideo
  module Tools
    class Mencoder
      include AbstractTool::InstanceMethods

      attr_reader :frame, :size, :time, :bitrate, :video_size, :audio_size, :output_fps
      
      def tool_command
        'mencoder'
      end

      def format_fps(params={})
        " -ofps %0.2f" % params[:fps].to_f
      end

      def format_resolution(params={})
        p = " -vf scale=#{params[:scale][:width]}:#{params[:scale][:height]}"
        if params[:letterbox]
          p += ",expand=#{params[:letterbox][:width]}:#{params[:letterbox][:height]}"
        end
        p += ",harddup"
      end

      def format_audio_channels(params={})
        " -channels #{params[:channels]}"
      end
      
      def format_audio_bit_rate(params={})
        " br=#{params[:bit_rate]}:"
      end
      
      def format_audio_sample_rate(params={})
        " -srate #{params[:sample_rate]}"
      end
      
      def format_video_quality(params={})
        bitrate = params[:video_bit_rate].blank? ? nil : params[:video_bit_rate]
        factor = (params[:scale][:width].to_f * params[:scale][:height].to_f * params[:fps].to_f)
        case params[:video_quality]
        when 'low'
          bitrate ||= (factor / 12000).to_i
          " -x264encopts threads=auto:subq=1:me=dia:frameref=1:crf=30:bitrate=#{bitrate} "
        when 'medium'
          bitrate ||= (factor / 9000).to_i
          " -x264encopts threads=auto:subq=3:me=hex:frameref=2:crf=22:bitrate=#{bitrate} "
        when 'high'
          bitrate ||= (factor / 3600).to_i
          " -x264encopts threads=auto:subq=6:me=dia:frameref=3:crf=18:bitrate=#{bitrate} "
        else
          ""
        end
      end  
      
      def execute_with_progress(&block)
        RVideo.logger.info("\nExecuting Command: #{@command}\n")
        do_execute_with_progress(@command, &block)
      rescue RVideo::CommandExecutor::ProcessHungError
        raise TranscoderError, "Transcoder hung."
      end
      
      def do_execute_with_progress(command,&block)
        @raw_result = ''
        stderr_result, stdout_result = CommandExecutor::execute_with_block(command, "\r", false) do |line|
          progress = parse_progress(line)
          block.call(progress) if block && progress
          @raw_result += line + "\r"
        end
        @raw_result += stderr_result
      end
      
      def parse_progress(line)
        if line =~ /Pos:[^(]*\((\d+)\%\)/
          $1.to_i > 100 ? 100 : $1.to_i
        else
          nil
        end
      end
      
      private
      
      def parse_result(result)
        if m = /Exiting.*No output file specified/.match(result)
          raise TranscoderError::InvalidCommand, "no command passed to mencoder, or no output file specified"
        end
        
        if m = /counldn't set specified parameters, exiting/.match(result)
          raise TranscoderError::InvalidCommand, "a combination of the recipe parameters is invalid: #{result}"
        end

        if m = /Sorry, this file format is not recognized\/supported/.match(result)
          raise TranscoderError::InvalidFile, "unknown format"
        end
        
        if m = /Cannot open file\/device./.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        if m = /File not found:$/.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        video_details = result.match /Video stream:(.*)$/
        if video_details
          @bitrate    = video_details[0][/Video stream:\s*([0-9.]*)/, 1]
          @video_size = video_details[0][/size:\s*(\d*)\s*(\S*)/, 1]
          @time       = video_details[0][/bytes\s*([0-9.]*)/, 1]
          @frame      = video_details[0][/secs\s*(\d*)/, 1]
          @output_fps = (@frame.to_f / @time.to_f).round_to(3)
        
        elsif result =~ /Video stream is mandatory/
          raise TranscoderError::InvalidFile,
            "Video stream required, and no video stream found"
        end
        
        audio_details = result.match /Audio stream:(.*)$/
        if audio_details
          @audio_size = audio_details[0][/size:\s*(\d*)\s*\S*/, 1]
        else
          @audio_size = 0
        end
        @size = (@video_size.to_i + @audio_size.to_i).to_s
      end
      
    end
  end
end
