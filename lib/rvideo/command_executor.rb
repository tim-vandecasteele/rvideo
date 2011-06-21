require 'posix/spawn'
require 'stringio'

module RVideo
  module CommandExecutor
    STDOUT_TIMEOUT = 200

    class ProcessHungError < StandardError; end

    # Utility function that scans for splits
    module EachSplit
      protected
      def each_split(string, separator=$/, last_pos=0)
        while pos = string.index(separator, last_pos+1)
          yield string[last_pos..pos]
          last_pos = pos + separator.size
        end
        last_pos
      end
    end

    class TailingStderrChild < POSIX::Spawn::Child
      include EachSplit
      private
      def read_and_write(input, stdin, stdout, stderr, timeout=nil, max=nil)
        max = nil if max && max <= 0
        out, err = '', []
        offset = 0

        # force all string and IO encodings to BINARY under 1.9 for now
        if out.respond_to?(:force_encoding)
          [stdin, stdout, stderr].each do |fd|
            fd.set_encoding('BINARY', 'BINARY')
          end
          out.force_encoding('BINARY')
          err.force_encoding('BINARY')
          input = input.dup.force_encoding('BINARY') if input
        end

        timeout = nil if timeout && timeout <= 0.0
        @runtime = 0.0
        start = Time.now

        readers = [stdout, stderr]
        writers =
          if input
            [stdin]
          else
            stdin.close
            []
          end
        t = timeout
        while readers.any? || writers.any?
          ready = IO.select(readers, writers, readers + writers, t)
          raise TimeoutExceeded if ready.nil?

          # write to stdin stream
          ready[1].each do |fd|
            begin
              boom = nil
              size = fd.write_nonblock(input)
              input = input[size, input.size]
            rescue Errno::EPIPE => boom
            rescue Errno::EAGAIN, Errno::EINTR
            end
            if boom || input.size == 0
              stdin.close
              writers.delete(stdin)
            end
          end

          # read from stdout and stderr streams
          ready[0].each do |fd|
            buf = (fd == stdout) ? out : err
            begin
              if fd == stderr
                tmp_str = buf.pop.to_s + fd.readpartial(BUFSIZE)
                last_pos = each_split(tmp_str) do |line|
                  buf << line
                end
                buf.shift(buf.size-max) if buf.size > max
                buf << tmp_str[last_pos..-1].to_s
              else
                buf << fd.readpartial(BUFSIZE)
              end
            rescue Errno::EAGAIN, Errno::EINTR
            rescue EOFError
              readers.delete(fd)
              fd.close
            end
          end

          # keep tabs on the total amount of time we've spent here
          @runtime = Time.now - start
          if timeout
            t = timeout - @runtime
            raise TimeoutExceeded if t < 0.0
          end
        end

        [out, err.join]
      end

    end

    class ChildWithBlock < POSIX::Spawn::Child
      include EachSplit

      def initialize(*args, &each_line)
        @env, @argv, options = extract_process_spawn_arguments(*args)
        @options = options.dup
        @input = @options.delete(:input)
        @timeout = @options.delete(:timeout)
        @io_timeout = @options.delete(:io_timeout)
        @max = @options.delete(:max)
        @line_separator = (@options.delete(:line_separator) || $/).to_s
        @each_select = @options.delete(:each_select) || :out
        @each_line = each_line
        @options.delete(:chdir) if @options[:chdir].nil?
        exec!
      end

      private
      def exec!
        # spawn the process and hook up the pipes
        pid, stdin, stdout, stderr = popen4(@env, *(@argv + [@options]))

        # async read from all streams into buffers
        @out, @err = read_and_write(@input, stdin, stdout, stderr, @timeout, @io_timeout, @max, @line_separator, @each_select, &@each_line)

        # grab exit status
        @status = waitpid(pid)
      rescue Object => boom
        [stdin, stdout, stderr].each { |fd| fd.close rescue nil }
        if @status.nil?
          ::Process.kill('TERM', pid) rescue nil
          @status = waitpid(pid)      rescue nil
        end
        raise
      ensure
        # let's be absolutely certain these are closed
        [stdin, stdout, stderr].each { |fd| fd.close rescue nil }
      end

      def read_and_write(input, stdin, stdout, stderr, timeout=nil, io_timeout=nil, max=nil, line_separator=$/, each_select=:out, &each_line)
        max = nil if max && max <= 0
        out, err = '', ''
        offset = 0

        # force all string and IO encodings to BINARY under 1.9 for now
        if out.respond_to?(:force_encoding)
          [stdin, stdout, stderr].each do |fd|
            fd.set_encoding('BINARY', 'BINARY')
          end
          out.force_encoding('BINARY')
          err.force_encoding('BINARY')
          input = input.dup.force_encoding('BINARY') if input
        end

        timeout = nil if timeout && timeout <= 0.0
        each_pos = 0
        @runtime = 0.0
        start = Time.now

        readers = [stdout, stderr]
        writers =
          if input
            [stdin]
          else
            stdin.close
            []
          end
        t = timeout
        while readers.any? || writers.any?
          ready = IO.select(readers, writers, readers + writers, (t && io_timeout && t < io_timeout) ? t : io_timeout)
          raise ProcessHungError if ready.nil?

          # write to stdin stream
          ready[1].each do |fd|
            begin
              boom = nil
              size = fd.write_nonblock(input)
              input = input[size, input.size]
            rescue Errno::EPIPE => boom
            rescue Errno::EAGAIN, Errno::EINTR
            end
            if boom || input.size == 0
              stdin.close
              writers.delete(stdin)
            end
          end

          # read from stdout and stderr streams
          ready[0].each do |fd|
            buf = (fd == stdout) ? out : err
            begin
              buf << fd.readpartial(BUFSIZE)
              if block_given? && (fd == (each_select == :err ? stderr : stdout))
                each_pos = each_split(buf, line_separator, each_pos, &each_line)
              end
            rescue Errno::EAGAIN, Errno::EINTR
            rescue EOFError
              readers.delete(fd)
              fd.close
              # Yield the last line if any
              if block_given? && (fd == (each_select == :err ? stderr : stdout))
                yield(buf[each_pos..-1]) if each_pos < buf.size
                each_pos = buf.size
              end
            end
          end

          # keep tabs on the total amount of time we've spent here
          @runtime = Time.now - start
          if timeout
            t = timeout - @runtime
            raise TimeoutExceeded if t < 0.0
          end

          # maybe we've hit our max output
          if max && ready[0].any? && (out.size + err.size) > max
            raise MaximumOutputExceeded
          end
        end

        [out, err]
      end

    end

    def self.execute_with_block(command, line_separator=$/, use_stderr = true, &each_line)
      child = ChildWithBlock.new(command, :io_timeout => STDOUT_TIMEOUT, :line_separator => line_separator, :each_select => (use_stderr ? :err : :out), &each_line)
      return [child.err, child.out]
    end

    def self.execute_tailing_stderr(command, number_of_lines = 500)
      child = TailingStderrChild.new(command, :max => number_of_lines, :timeout => 24 * 60 * 60)
      child.err
    end
  end
end
