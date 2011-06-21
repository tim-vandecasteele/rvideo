require File.dirname(__FILE__) + '/../spec_helper'

include RVideo

describe RVideo::CommandExecutor do

  # Change the default timeout
  RVideo::CommandExecutor.send(:remove_const, "STDOUT_TIMEOUT")
  RVideo::CommandExecutor.const_set("STDOUT_TIMEOUT", 1.5)

  before(:each) do
    @file = "/tmp/command_executor_tmp_output"
    FileUtils.rm_f(@file)
  end
  
  
  describe "exectue_tailing_stderr" do
    
    it "should execute command" do
      CommandExecutor::execute_tailing_stderr("echo abc 1>&2").should == "abc\n"      
    end
    
    it "should return only specified number of lines from output" do
      CommandExecutor::execute_tailing_stderr("echo abc 1>&2; echo def 1>&2; echo ghi 1>&2; echo jkl 1>&2;", 2).should == "ghi\njkl\n" 
    end
    
  end
  

  describe "execute with block" do

    it "should execute command" do
      CommandExecutor::execute_with_block("echo abc > #{@file}")
      File.read(@file).chop.should == "abc"
    end

    it "should exit before command finishes if there is no output within timeout" do
      lambda {
        CommandExecutor::execute_with_block("sleep 2; echo abc > #{@file}")
      }.should raise_error(RVideo::CommandExecutor::ProcessHungError)
      File.exist?(@file).should be_false
    end

    it "should not exit if command doesn't exit timeout" do
      CommandExecutor::execute_with_block("sleep 1; echo abc > #{@file}")
      File.read(@file).chop.should == "abc"
    end

    it "should yield block for each line of stderr" do
      string = ""
      CommandExecutor::execute_with_block("echo abc 1>&2; echo def 1>&2") do |line|
        string << line
      end
      string.should == "abc\ndef\n"
    end

    it "should stop reading IO when timeout exceeds" do
      string = ""
      lambda {
        CommandExecutor::execute_with_block("sleep 1; echo abc 1>&2; sleep 1; echo def 1>&2; sleep 2;  echo ghi 1>&2") do |line|
          string << line
        end
      }.should raise_error(RVideo::CommandExecutor::ProcessHungError)
      string.should == "abc\ndef\n"
    end

    it "should not return line from stdout" do
      string = ""
      CommandExecutor::execute_with_block("echo abc; echo def 1>&2;") do |line|
        string << line
      end
      string.should == "def\n"
    end

    it "should kill the process" do
      number = rand(100000000000) + 100000
      lambda {
        CommandExecutor::execute_with_block("sleep #{number}")
      }.should raise_error(RVideo::CommandExecutor::ProcessHungError)
      `ps aux | grep #{number} | grep -v grep`.should be_empty
    end
  end

  it "should save stdout and stderr" do
    string = ""
    stderr_res = nil
    stdout_res = nil
    stderr_res, stdout_res = CommandExecutor::execute_with_block("echo abc; echo def 1>&2;", '\r') do |line|
      string << line
    end
    
    stderr_res.should == "def\n"
    stdout_res.should == "abc\n"
  end

  it "should save stdout and stderr using stdout" do
    string = ""
    stderr_res = nil
    stdout_res = nil
    stderr_res, stdout_res = CommandExecutor::execute_with_block("echo abc; echo def 1>&2;", '\r', false) do |line|
      string << line
    end
    
    stderr_res.should == "def\n"
    stdout_res.should == "abc\n"
  end

end
