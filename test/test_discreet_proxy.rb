require 'helper'

class TestDiscreetProxy < Test::Unit::TestCase
  def test_reading
    f = DiscreetProxy.from_file(File.dirname(__FILE__) + "/test_proxies/e292_v02.batch.p")
    assert_equal 126, f.width, "Width should be correct"
    assert_equal 92, f.height, "Height should be correct"
  end
  
  def test_reading_from_io
    chunk = File.read(File.dirname(__FILE__) + "/test_proxies/e292_v02.batch.p")
    io = StringIO.new(chunk)
    f = DiscreetProxy.from_io(io)
    assert_equal 126, f.width, "Width should be correct"
    assert_equal 92, f.height, "Height should be correct"
  end
  
  def test_to_dotp
    Dir.glob(File.dirname(__FILE__) + "/test_proxies/*.p").each do | f |
      proxy = DiscreetProxy.from_file(f)
      repl = '/tmp/%s.p' % File.basename(f)
      message = "Roundtripping #{File.basename(f)}"
      
      pixdata = proxy.to_dotp # Package up
      proxy_roundtrip = DiscreetProxy.from_io(StringIO.new(pixdata))
      assert_equal proxy_roundtrip.to_png, proxy.to_png, message
    end
  end
  
  def test_pixmap_values
    path = File.dirname(__FILE__) + "/test_proxies/Kanaty.stabilizer.p"
    proxy = DiscreetProxy.from_file(path)
    assert_equal [46, 68, 69], proxy[23,78]
    
    proxy[23,78] = [50, 50, 50]
    
    assert_equal [50,50,50], proxy[23,78]
    assert_equal [43, 67, 69], proxy[23,79], "Should not have touched the values in another row"
  end
  
  def test_initialize_default
    proxy = DiscreetProxy::Proxy.new
    assert_equal 126, proxy.width
    assert_equal 92, proxy.height
    assert_equal [0,0,0], proxy[15,18]
  end
  
  def test_to_png
    Dir.glob(File.dirname(__FILE__) + "/test_proxies/*.p").each do | f |
      proxy = DiscreetProxy.from_file(f)
      png_path = File.dirname(__FILE__) + "/converted_png_proxies/%s.p.png" % File.basename(f)
      chunky_png = proxy.to_png
      assert_equal chunky_png, ChunkyPNG::Image.from_file(png_path)
    end
  end
  
  def test_from_png
    f = File.dirname(__FILE__) + "/converted_png_proxies/Kanaty.stabilizer.p.p.png"
    png = ChunkyPNG::Image.from_file(f)
    proxy = DiscreetProxy.from_png(png)
    roundtrip_png = proxy.to_png
    
    dest = '/tmp/foo_%s' % File.basename(f)
    assert_equal png, roundtrip_png
  end
  
  TEST_OUTPUT = "./test.p"
  TEST_PNG = "./test.png"
  
  def unlink_testfiles
    [TEST_OUTPUT, TEST_PNG].each{|f| File.unlink(f) if File.exist?(f) }
  end
  alias_method :setup, :unlink_testfiles
  alias_method :teardown, :unlink_testfiles
  
  def test_save
    path = File.dirname(__FILE__) + "/test_proxies/Kanaty.stabilizer.p"
    ref_output = File.dirname(__FILE__) + "/test_proxy_out/Kanaty.stabilizer.p"
    proxy = DiscreetProxy.from_file(path)
    proxy.save(TEST_OUTPUT)
    assert File.exist?(TEST_OUTPUT)
    assert_equal File.read(TEST_OUTPUT), File.read(ref_output)
  end
  
  def test_save_png
    path = File.dirname(__FILE__) + "/test_proxies/Kanaty.stabilizer.p"
    proxy = DiscreetProxy.from_file(path)
    proxy.save_png(TEST_PNG)
    assert File.exist?(TEST_PNG)
    assert_equal ChunkyPNG::Image.from_file(TEST_PNG), proxy.to_png
  end
end