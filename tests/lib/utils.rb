class Utils

  def self.run3(command, args, sin, output_limit)
    streams = Open3.popen3(command, *args) do |stdin, stdout, stderr, wait_thr|
      t0 = Thread.start do
        if sin
          stdin.print(sin)
          stdin.flush
        end
        stdin.close
      end

      r_stdout = nil

      t1 = Thread.start do
        r_stdout = stdout.read(output_limit)
      end

      r_stderr = nil

      t2 = Thread.start do
        r_stderr = stderr.read(output_limit)
      end

      t0.join
      t1.join
      t2.join

      { :stdout => r_stdout, :stderr => r_stderr, :exit_status => wait_thr.value}
    end

    streams[:exit_status] = streams[:exit_status].exitstatus
    return streams
  end

end
