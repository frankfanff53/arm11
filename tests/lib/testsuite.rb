
require 'fileutils'
require 'open3'
require 'tmpdir'

require 'json'

require 'utils.rb'

class TestSuite

  public

  def initialize(test_cases_path, emulate_assemble_path)
    @test_cases_path       = File.absolute_path(test_cases_path)
    @emulate_assemble_path = File.absolute_path(emulate_assemble_path)

    @emulate  = File.absolute_path(File.join(emulate_assemble_path,"emulate"))
    @assemble = File.absolute_path(File.join(emulate_assemble_path,"assemble"))

    sources

  end

  # recomputes the sources and stores them
  def sources
    @sources = Dir.glob(File.join(@test_cases_path,"**","*.s")).sort
    @sources
  end

  # takes a block argument which is called back by each result
  def run_tests(&block)

    @sources.each do |source|
      result = test_source(File.absolute_path(source))
      block.call({ :source => source, :result => result })
    end

  end

  def run_test(source, &block)
    if @sources.member?(source) then
      result = test_source(source)
      block.call({:source => source, :result => result})
    end
  end

  private

  def test_source(source)

    binary = source.sub(/\.s$/,"")

    emulator_results  = run_emulate(binary)
    assembler_results = run_assemble(source, binary)

    { :source => source,
      :binary => binary,
      :emulator => emulator_results,
      :assembler => assembler_results,
      :passed => emulator_results[:passed] && assembler_results[:passed]
    }
  end

  def run_emulate(binary_path)

    unless File.exists?(@emulate) then
      return { :result => :error,
               :passed => false,
               :message => "emulate binary cannot be found"
             }
    end

    # TODO: check the files exist etc.
    expected_out_file = binary_path + ".out"
    expected_err_file = binary_path + ".err"

    expected_out = File.exist?(expected_out_file) ?
                    File.open(expected_out_file, "r") { |f| f.read } : nil
    expected_err = File.exist?(expected_err_file) ?
                    File.open(expected_err_file, "r") { |f| f.read } : nil

    run_results = nil

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        run_results = Utils.run3("/usr/local/bin/timeout",
                           ["--kill-after=5", "3", @emulate, binary_path],
                           nil, 1024 * 1024 * 100)
      end
    end

    passed = (expected_out == run_results[:stdout]) &&
             (expected_err == run_results[:stderr]) &&
             (run_results[:exit_status] == 0)

    return { :result => :ran,
             :passed => passed,
             :run_results => run_results,
             :expected    => { :stdout => expected_out,
                               :stderr => expected_err
                             }
           }
  end

  def run_assemble(source_path, binary_path)
    unless File.exists?(@assemble) then
      return { :result => :error,
               :passed => false,
               :message => "assemble binary cannot be found"
             }
    end

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        run_results = Utils.run3("/usr/local/bin/timeout",
                                 ["--kill-after=5", "3", @assemble, source_path,
                                  "out"],
                                 nil, 1024 * 1024 * 100)


        expected_contents =
          IO.popen(["/usr/bin/xxd", "-c4", "-g4", binary_path]) { |io| io.read }


        unless File.exist?("out") then
          return { :result        => :ran,
                   :passed        => false,
                   :run_results   => run_results,
                   :actual_bin    => "<no output file produced>",
                   :expected_bin  => expected_contents
                 }
        end

        produced_contents =
          IO.popen(["/usr/bin/xxd", "-c4", "-g4", "out"]) { |io| io.read }

        passed = produced_contents == expected_contents &&
                  run_results[:exit_status] == 0
        return {  :result       => :ran,
                  :passed       => passed,
                  :run_results  => run_results,
                  :actual_bin   => produced_contents,
                  :expected_bin => expected_contents
                }

      end
    end

  end

end
