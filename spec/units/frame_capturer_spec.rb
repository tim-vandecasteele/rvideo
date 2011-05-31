require File.dirname(__FILE__) + '/../spec_helper'

module RVideo
  describe FrameCapturer, "calculating offset from a timecode argument" do
    before do
      @file = FrameCapturer.new :input => spec_file('kites.mp4')
    end
  
    it "should calculate a timecode, when given a percentage" do
      @file.inspector.duration.should == 19600
      @file.calculate_time("10%").should be_within(1.96).of(0.1)
      @file.calculate_time("1%").should be_within(0.196).of(0.001)
      @file.calculate_time("75%").should be_within(14.7).of(0.1)
      @file.calculate_time("100%").should be_within(19.6).of(0.1)
    end
  
    it "should calculate a timecode, when given a frame" do
      @file.inspector.fps.to_i.should == 10
      @file.calculate_time("10f").should be_within(1.0).of(0.1)
      @file.calculate_time("27.6f").should be_within(2.76).of(0.1)
    
      @file.inspector.stub!(:fps).and_return(29.97)
      @file.calculate_time("276f").should be_within(9.2).of(0.1)
      @file.calculate_time("10f").should be_within(0.3).of(0.1)
      @file.calculate_time("29.97f").should be_within(1.0).of(0.01)
    end
    
    it "should return itself when given seconds" do
      [1, 10, 14, 3.7, 2.8273, 16].each do |t|
        @file.calculate_time("#{t}s").should == t
      end
    end
  
    it "should return itself when given no letter" do
      [1, 10, 14, 3.7, 2.8273, 16].each do |t|
        @file.calculate_time("#{t}").should == t
      end
    end
  
    it "should return a frame at 99%, when given something outside of the bounds of the file" do
      nn = @file.calculate_time("99%")
      %w(101% 20s 99 300f).each do |tc|
        @file.calculate_time(tc).should be_within(nn).of(0.01)
      end
    end
  
    ###
  
    it "captures one frame at the start with no arguments" do
      f = FrameCapturer.new :input => spec_file('kites.mp4')
      f.command.should == \
        %{ffmpeg -i '#{f.input}' -ss 0  -vframes 1  -vcodec mjpeg  -y -f image2 -vf 'scale=176:144' '#{f.output}'}
    end
  
    it "captures one frame with only offset" do
      f = FrameCapturer.new :input => spec_file('kites.mp4'), :offset => 10
      f.command.should == \
        %{ffmpeg -i '#{f.input}' -ss 10.0  -vframes 1  -vcodec mjpeg  -y -f image2 -vf 'scale=176:144' '#{f.output}'}
    end
  
    it "captures using any ffmpeg binary" do
      f = FrameCapturer.new :input => spec_file('kites.mp4'), :ffmpeg_binary => "ffmpeg06"
      f.command.should == \
        %{ffmpeg06 -i '#{f.input}' -ss 0  -vframes 1  -vcodec mjpeg  -y -f image2 -vf 'scale=176:144' '#{f.output}'}
    end
  end
end
