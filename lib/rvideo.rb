# core extensions
require 'rvideo/float'
require 'rvideo/string'

# gems
require 'active_support'
require 'active_support/inflector'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/object/blank'

require 'open4'

# rvideo
require 'rvideo/command_executor'
require 'rvideo/inspector'
require 'rvideo/frame_capturer'
require 'rvideo/errors'
require 'rvideo/transcoder'
require 'rvideo/tools/abstract_tool'
require 'rvideo/tools/ffmpeg'
require 'rvideo/tools/mencoder'
require 'rvideo/tools/flvtool2'
require 'rvideo/tools/mp4box'
require 'rvideo/tools/mplayer'
require 'rvideo/tools/mp4creator'
require 'rvideo/tools/ffmpeg2theora'
require 'rvideo/tools/yamdi'
require 'rvideo/tools/qtfaststart'
require 'rvideo/tools/segmenter'
require 'rvideo/tools/handbrakecli'
require 'rvideo/tools/lame'

module  RVideo
  def self.logger=(logger)
    @logger = logger
  end
  
  def self.logger
    @logger = Logger.new("/dev/null") unless @logger
    @logger
  end
end
