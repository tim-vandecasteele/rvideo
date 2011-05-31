require File.dirname(__FILE__) + '/../spec_helper'

module RVideo
  describe FrameCapturer do
    before do
      FileUtils.mkdir_p TEMP_PATH
    end

    after do
      FileUtils.rm_rf TEMP_PATH
    end

    it "should create a screenshot with a custom output path" do
      output_file = TEMP_PATH + "/kites.jpg"

      file = FrameCapturer.new(:input => spec_file("kites.mp4"), :offset => "10%", :output => output_file)
      file.capture!.should == [output_file]

      FileTest.exist?(output_file).should be_true
    end
  end
end
