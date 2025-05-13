# frozen_string_literal: true

require_relative "helper"
require "cli_test"

class CliTest < Minitest::Test
  TEMP_DIR = File.expand_path(File.dirname(__FILE__) + "/tmp")
  BIN_P = File.expand_path(File.dirname(__FILE__) + "/../bin/flame_proxy_icon")
  
  def setup
    Dir.mkdir(TEMP_DIR) unless File.exist?(TEMP_DIR)
  end
  
  def teardown
    FileUtils.rm_rf(TEMP_DIR)
  end
  
  # Run the tracksperanto binary with passed options, and return [exit_code, stdout_content, stderr_content]
  def cli(commandline_arguments)
    CLITest.new(BIN_P).run(commandline_arguments)
  end
  
  def test_cli_with_no_args_produces_usage
    status, _o, e = cli('')
    assert_equal 1, status
    assert_match( /Also use the --help option/, e)
  end
  
  def test_cli_from_png
    FileUtils.cp(File.dirname(__FILE__) + "/converted_png_proxies/Kanaty.stabilizer.p.p.png", TEMP_DIR)
    status, _o, e = cli("--from-png #{TEMP_DIR}/Kanaty.stabilizer.p.p.png")
    assert status.zero?, e
    assert File.exist?(TEMP_DIR + "/Kanaty.stabilizer.p.p.p")
  end
  
  def test_cli_from_p
    FileUtils.cp(File.dirname(__FILE__) + "/test_proxies/Kanaty.stabilizer.p", TEMP_DIR)
    
    status, _o, e = cli("--from-icon #{TEMP_DIR}/Kanaty.stabilizer.p")
    assert status.zero?, e
    assert File.exist?(TEMP_DIR + "/Kanaty.stabilizer.png")
  end
  
end