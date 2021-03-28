class TestSuiteRunner

  require 'thread'
  require 'testsuite'

  def initialize(test_cases_path, emulate_assemble_path)
    @mutex = Mutex.new
    @test_suite = TestSuite.new(test_cases_path, emulate_assemble_path)

    # guarded variables
    @status = :not_run_yet
    @test_cases = []
    @test_results = {}
  end

  def rerun_tests
    @mutex.synchronize do
      case @status
      when :not_run_yet
        go_run_tests
      when :running
        # currently running - ignore and do nothing
      when :ran
        go_run_tests
      end
    end
  end

  def run_one(target_file)
    @mutex.synchronize do
      case @status
      when :not_run_yet
        go_run_one(target_file)
      when :running
        # currently running - ignore and do nothing
      when :ran
        go_run_one(target_file)
      end
    end
  end

  def status
    @mutex.synchronize do
      { :status       => @status,
        :test_cases   => @test_cases.dup,
        :test_results => @test_results.dup
      }
    end
  end

  private

  # assumes the mutex is currently held
  def go_run_tests
    @status = :running
    Thread.new do
      begin
        test_cases = @test_suite.sources

        @mutex.synchronize do
          @test_cases = test_cases
          @test_results = {}
        end

        @test_suite.run_tests do |result|
          @mutex.synchronize do
            @test_results[result[:source]] = result[:result]
          end
        end

      rescue => e
        puts e
        print e.bracktrace.join("\n")
      ensure
        @status = :ran
      end

    end
  end

  # assumes the mutex is currently held
  def go_run_one(test_case)
    @status = :running
    Thread.new do
      begin
        @test_suite.run_test(test_case) do |result|
          @test_results[result[:source]] = result[:result]
        end
      rescue => e
        puts e
        print e.bracktrace.join("\n")
      ensure
        @status = :ran
      end
    end
  end

end
