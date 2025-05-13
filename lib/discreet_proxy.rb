require "chunky_png"

# The whole module for making and reading Flame proxy icon files
module DiscreetProxy
  VERSION = "1.0.1"
  
  # Parse a .p file and return a Proxy
  def self.from_file(path)
    File.open(path, "rb") {|f| from_io(f) }
  end
  
  # Creates a proxy object from a passed ChunkyPNG
  def self.from_png(png)
    p = Proxy.new(png.width, png.height)
    (0...png.width).each do | x |
      (0...png.height).each do | y |
        p[x,y] = png[x,y]
      end
    end
    p
  end
  
  # Parses out the proxy contained in the passed IO object
  def self.from_io(io)
    pat = "na6nnn"
    
    magik, version_bswap, width, height, depth, _ = io.read(40).unpack(pat)
    raise "The passed data did not start with the magic bytes #{MAGIC}" if magik != MAGIC
    
    # This version check is busted for now, somehow
    ver = version_bswap.reverse.unpack("e").pop
    $stderr.puts "The passed version #{ver} is suspicious" if (ver - PROXY_VERSION).abs > 0.0001
    raise "Unknown proxy depth #{depth}" if depth != PROXY_DEPTH
    
    p = Proxy.new(width, height)
    p.fill_pixbuf(io)
    return p
  end
  
  MAGIC = 0xfaf0
  PROXY_VERSION = 1.10003
  PROXY_DEPTH = 130
  VERSION_BSWAP = "\x00\x00?\x8C\xCC\xCD"
  DEFAULT_WIDTH = 126
  DEFAULT_HEIGHT = 92

  # This class represents a proxy.
  class Proxy
    
    # Image dimensions, standard is 126x92
    attr_reader :width, :height
    
    # Array of rows with each row being an array of packed color 
    # integers (you can unpack them with ChunkyPNG::Color)
    attr_reader :rows 
    
    def initialize(w = DEFAULT_WIDTH, h = DEFAULT_HEIGHT)
      @width, @height = w.to_i, h.to_i
      # Blank out the pixel values with black
      generate_black
    end
    
    def to_png
      png = ChunkyPNG::Image.new(@width, @height)
      png.metadata["Software"] = "Ruby DiscreetProxy converter/chunky_png"
      @rows.each_with_index do | row, y |
        png.replace_row!(y, row)
      end
      # Bump it to the default icon size
      png.resample_bilinear!(DEFAULT_WIDTH, DEFAULT_HEIGHT)
      png
    end
    
    # Get an array of the [r,g,b] pixel values at the specific coordinate
    def [](left, top)
      png_color_int = @rows[top][left]
      unpack_rgb(png_color_int)
    end
    
    # Set the color value at the specific coordinate. If the passed value is a single
    # integer, it gets interpreted as a PNG color value. If a triplet array with three
    # components is passed it's interpreted as RGB
    def []=(x, y, *rgb)
      color = rgb.flatten
      
      # Check for raw pixel value
      if color.length == 1 && color[0].is_a?(Numeric)
        @rows[y][x] = color[0]
      else
        r, g, b = color.map{|e| e.to_i }
        @rows[y][x] = pack_rgb(r, g ,b)
      end
    end
    
    # Compose a string with the entire contents of a proxy file
    def to_dotp
      # Pack the header
      buf = StringIO.new(0xFF.chr * 40)
      header = [MAGIC, VERSION_BSWAP, width, height, PROXY_DEPTH].pack("na6nnn")
      buf.write(header)
      buf.seek(40)
      
      # Write out all the rows starting with the last one
      @rows.reverse.each do | row |
        row.each do | pix |
          rgb = unpack_rgb(pix).pack("CCC")
          buf.write(rgb) 
        end
        # Then write the padding
        buf.write(0x00.chr * row_pad)
      end
      
      buf.string
    end
    
    # Once the proxy metadata is known, this method can parse out the actual pixel data
    # from the passed IO
    def fill_pixbuf(io)
      @rows = []
      
      # Data comes in row per row, starting on bottom left because of endianness
      per_row = (@width.to_i + row_pad) * 3
      total_size = ((per_row + row_pad) * @height) + 1
      blob = StringIO.new(io.read(total_size))
      
      @height.times do
        row = []
        row_data = blob.read(@width.to_i * 3)
        row_data = StringIO.new(row_data.to_s)
        
        # Read 3x8bit for each pixel
        @width.times do
          rgb = (row_data.read(3) || "AAA").unpack("CCC")
          row.push(pack_rgb(*rgb))
        end
        
        # At the end of each row (thus at the beginning byteswap),
        # 2 bytes contain garbage since rows are aligned
        # to start at 8-complement byte offsets. If they are not discarded this disturbs
        # the RGB cadence of the other values.
        blob.seek(blob.pos + row_pad)
        
        # Since the file is actually BE, the rows are ordered top to bottom in the file
        @rows.unshift(row)
      end
    end
    
    # Save out the .p file
    def save(filename)
      File.open(filename, 'wb') { |io| io.write(to_dotp) }
    end
    
    # Save out the PNG version of the file
    def save_png(filename)
      to_png.save(filename)
    end
    
    private
    
    # Rows start at 8-byte aligned boundaries. BUT due to the
    # fact that this is a BDSM Silicon Graphics format the start of the row is END of the image.
    def row_pad
      @row_pad ||= ((@width * 3) % 8)
    end
    
    def pack_rgb(r,g,b)
      ChunkyPNG::Color.rgb(r.to_i, g.to_i, b.to_i)
    end
    
    def unpack_rgb(rgb)
      [ChunkyPNG::Color.r(rgb), ChunkyPNG::Color.g(rgb), ChunkyPNG::Color.b(rgb)]
    end
    
    def generate_black
      @rows = []
      row = [0] * @width
      @height.times{ @rows.push(row.dup) }
    end
  end
  
end