require 'webrick'

require 'json'


class ServletStatus < WEBrick::HTTPServlet::AbstractServlet

  def initialize(config, test_suite_runner)
    super
    @test_suite_runner = test_suite_runner
  end

  def do_GET(req, resp)
    resp['content-type'] = 'application/json'
    resp.body = JSON.dump(@test_suite_runner.status)
  end

end

class ServletRun < WEBrick::HTTPServlet::AbstractServlet

  def initialize(config, test_suite_runner)
    super
    @test_suite_runner = test_suite_runner
  end

  def do_POST(req, resp)
    @test_suite_runner.rerun_tests
    resp.body = ""
  end

end

class ServletRunOne < WEBrick::HTTPServlet::AbstractServlet

  def initialize(config, test_suite_runner)
    super
    @test_suite_runner = test_suite_runner
  end

  def do_POST(req, resp)
    target_file = File.absolute_path(req.path_info)
    @test_suite_runner.run_one(target_file)
    resp.body = ""
  end

end


class ServletTestSourceFile < WEBrick::HTTPServlet::AbstractServlet
  def initialize(config, test_cases_path)
    super
    @test_cases_path = File.absolute_path(test_cases_path)
  end

  def do_GET(req, resp)

    target_file = File.absolute_path(req.path_info)

    if target_file.start_with?(@test_cases_path) and
       target_file.end_with?(".s") then

      contents = IO.popen(["/usr/bin/nl", "-w3", target_file]) { |io| io.read }

      resp['content-type'] = 'text/plain';
      resp.body = contents
      return
    end

    resp.status = 404
    resp.body = "Not found #{target_file} #{@test_cases_path}"
    resp['content-type'] = 'text/plain'
  end

end

class ServletTestBinaryFile < WEBrick::HTTPServlet::AbstractServlet
  def initialize(config, test_cases_path)
    super
    @test_cases_path = File.absolute_path(test_cases_path)
  end

  def do_GET(req, resp)

    target_file = File.absolute_path(req.path_info)

    if target_file.start_with?(@test_cases_path) then

      contents = IO.popen(["/usr/bin/xxd", "-c4", "-g4", target_file]) { |io| io.read }

      resp['content-type'] = 'text/plain';
      resp.body = contents
      return
    end

    resp.status = 404
    resp.body = "Not found #{target_file} #{@test_cases_path}"
    resp['content-type'] = 'text/plain'
  end

end
