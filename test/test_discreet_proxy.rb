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
      pixdata = proxy.to_dotp # Package up
      
      puts "Roundtripping #{File.basename(f)}"
      proxy_roundtrip = DiscreetProxy.from_io(StringIO.new(pixdata))
      assert_equal proxy_roundtrip.to_png, proxy.to_png
    end
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
    Dir.glob(File.dirname(__FILE__) + "/converted_png_proxies/*.png").each do | f |
      png = ChunkyPNG::Image.from_file(f)
      proxy = DiscreetProxy.from_png(png)
      roundtrip_png = proxy.to_png
      assert_equal png, roundtrip_png
    end
  end
  
  def test_save
    flunk
  end
  
  def test_save_png
    flunk
  end
end