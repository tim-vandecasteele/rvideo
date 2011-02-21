require 'open4'

class IO

  def each_with_timeout(timeout, sep_string=$/)
    q = Queue.new
    th = nil

    timer_set = lambda do |timeout|
      th = new_thread{ to(timeout){ q.pop } }
    end

    timer_cancel = lambda do |timeout|
      th.kill if th rescue nil
    end

    timer_set[timeout]
    begin
      self.each(sep_string) do |buf|
        timer_cancel[timeout]
        yield buf
        timer_set[timeout]
      end
    ensure
      timer_cancel[timeout]
    end
  end

  private

  def new_thread *a, &b
    cur = Thread.current
    Thread.new(*a) do |*a|
      begin
        b[*a]
      rescue Exception => e
        cur.raise e
      end
    end
  end

  def to timeout = nil
    Timeout.timeout(timeout){ yield }
  end

end


module RVideo
  module CommandExecutor
    class ProcessHungError < StandardError; end

    STDOUT_TIMEOUT = 200

    def self.execute_with_block(command, line_separator=$/, use_stderr = true)
      begin
        pid, stdin, stdout, stderr = Open4::open4(command)
        c_pipe = use_stderr ? stderr : stdout
        pipe_result = ''

        c_pipe.each_with_timeout(STDOUT_TIMEOUT, line_separator) do |line|
          yield line
          pipe_result += line
        end
          Process.kill("SIGKILL", pid)
          Process.waitpid2 pid
          
          stdout_result = use_stderr ? stdout.read : pipe_result
          stderr_result =  use_stderr ? pipe_result : stderr.read
          
          [stdin, stdout, stderr].each{|io| io.close}
          
          return [stderr_result, stdout_result]
      rescue Timeout::Error => e
          Process.kill("SIGKILL", pid)
          Process.waitpid2 pid
          [stdin, stdout, stderr].each{|io| io.close}
        raise ProcessHungError
      end
    end
    
    def self.execute_tailing_stderr(command, number_of_lines = 500)
      result = String.new
      open4(command) do |pid, i, o, e|
        open4.spawn "tail -n #{number_of_lines}", :stdin=>e, :stdout=>result, :stdin_timeout => 24*60*60
      end
      result
    end

  end
end
