require File.dirname(__FILE__) + "/../spec_helper"
module RVideo
  
  describe Inspector, "with boat.avi" do
    
    before(:each) do
      @i = Inspector.new :file => spec_file("boat.avi")
    end
    
    it "is valid" do
      @i.should be_valid
    end
    
    it "knows the bitrate" do
      @i.bitrate.should == 2078
    end
    
    it "knows the bitrate units" do
      @i.bitrate_units.should == "kb/s"
    end
    
    it "gives the bitrate and units together" do
      @i.bitrate_with_units.should == "2078 kb/s"
    end
    
    it "knows the duration in milliseconds" do
      @i.duration.should == 15160
    end
    
    it "gives the duration as a string with : separating units of time" do
      @i.raw_duration.should == "00:00:15.16"
    end
    
    ###
    
    it "knows the video codec" do
      @i.video_codec.should == "mjpeg"
    end
    
    it "knows the resolution" do
      @i.resolution.should == "320x240"
    end
    
    it "knows the width" do
      @i.width.should == 320
    end
    
    it "knows the height" do
      @i.height.should == 240
    end
    
    ###
    
    it "knows the audio codec" do
      @i.audio_codec.should == "adpcm_ima_wav"
    end
    
    it "knows the audio sample rate" do
      @i.audio_sample_rate.should == 11025
    end
    
    it "knows the audio sample rate units" do
      @i.audio_sample_rate_units.should == "Hz"
    end
    
    it "gives the audio sample rate and units together" do
      @i.audio_sample_rate_with_units.should == "11025 Hz"
    end
    
    it "knows the audio channels" do
      @i.audio_channels.should == 1
    end
    
    it "gives the audio channels as a string" do
      @i.audio_channels_string.should == "1 channels"
    end
    
    it "knows the audio bit rate" do
      @i.audio_bit_rate.should == 44
    end
    
    it "knows the audio bit rate units" do
      @i.audio_bit_rate_units.should == "kb/s"
    end
    
    it "gives the audio bit rate with units" do
      @i.audio_bit_rate_with_units.should == "44 kb/s"
    end
    
    it "knows the audio sample bit depth" do
      @i.audio_sample_bit_depth.should == 16
    end
    
    # Input #0, avi, from 'spec/files/boat.avi':
    #   Duration: 00:00:15.16, start: 0.000000, bitrate: 2078 kb/s
    #     Stream #0.0: Video: mjpeg, yuvj420p, 320x240, 15.10 tbr, 15.10 tbn, 15.10 tbc
    #     Stream #0.1: Audio: adpcm_ima_wav, 11025 Hz, mono, s16, 44 kb/s
  end
  
  describe Inspector, "with kites.mp4" do
    before(:each) do
      @i = Inspector.new :file => spec_file("kites.mp4")
    end
    
    it "knows the pixel aspect ratio" do
      @i.pixel_aspect_ratio.should == "1:1"
    end
    
    it "knows the display aspect ratio" do
      @i.display_aspect_ratio.should == "11:9"
    end
  end
    
end