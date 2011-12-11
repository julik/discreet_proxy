require "chunky_png"

# The whole module for making and reading Flame proxy icon files
class DiscreetProxy
  VERSION = "0.0.1"
  
  # Parse a .p file and return a Proxy
  def self.from_file(path)
    File.open(path, "rb") {|f| from_io(f) }
  end
  
  # Creates a proxy object from a passed ChunkyPNG
  def self.from_png(png)
    p = Proxy.new(png.width, png.height)
    p.rows = []
    (0..png.height).each_with_index do | _, i|
      # Read the whole row at offset at once
      row = png.pixels[(i * png.width)...((i * png.width) + png.width)]
      p.rows.push(row)
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
  
  # Here's what Autodesk has to say:
  #
  # You can use Flame to create a proxy of your effect, but if you don't have access to Flame, 
  # or want to create proxies programmatically, you
  # can use the following header (byteswap). The standard width and height of the proxy is 126x92, and the
  # file is RGB 8-bit. Save your proxy files as .p, and place them in the same folder as your .glsl and .xml
  # files of the same name.
  # 
  #typedef struct {
  #        unsigned short Magic;
  #        float  Version; // 6 bytes long
  #        short  Width;
  #        short  Height;
  #        short  Depth;
  #        float  Unused [ 6 ];
  #} LibraryProxyHeaderStruct;
  # and this bitch is 6 bytes aligned
  #
  ##define MAGIC 0xfaf0
  ##define PROXY_VERSION 1.1f
  ##define PROXY_DEPTH 130
  #
  # This class represents such a proxy.
  class Proxy
    
    # Image dimensions, standard is 126x92
    attr_accessor :width, :height
    
    # Array of rows with each row being an array of 3-valut RGB triplets
    attr_accessor :rows 
    
    def initialize(w, h)
      @width, @height = w.to_i, h.to_i
    end
    
    def to_png
      png = ChunkyPNG::Image.new(@width, @height)
      png.metadata["Software"] = "Ruby DiscreetProxy converter/chunky_png"
      @rows.each_with_index do | row, row_idx |
        row.each_with_index do | pix, col_idx |
          png[col_idx, row_idx] = pix
        end
      end
      png
    end
    
    
    # Compose a string with the entire contents of a proxy file
    def to_dotp
      # Pack the header
      buf = StringIO.new(0xFF.chr * 40)
      byteswap_version = [PROXY_VERSION].pack("e").reverse
      header = [MAGIC, byteswap_version, width, height, PROXY_DEPTH].pack("na6nnn")
      buf.write(header)
      buf.seek(40)
      
      # Now... all the reverses come in reverse
      @rows.reverse.each do | returning_row |
        returning_row.each do | pix |
          rgb = unpack_rgb(pix).pack("CCC")
          buf.write(rgb) 
        end
        # Then write the padding
        buf.write(0x00.chr * row_pad)
      end
      
      buf.string
    end
    
    # Rows start at 8-byte aligned boundaries. BUT due to the
    # fact that this is a BDSM Silicon Graphics format the start of the row is END of the image.
    def row_pad
      @row_pad ||= ((@width * 3) % 8)
    end
    
    # Once the proxy metadata is known, this method can parse out the actual pixel data
    # from the passed IO
    def fill_pixbuf(io)
      @rows = []
      
      # Data comes in row per row, starting on lower left with
      # the values in the row being mirrored
      per_row = (@width.to_i + row_pad) * 3
      total_size = (per_row * @height) + 1
      # First byteswap is when reading rows. We want to read from
      # the bottom, so...
      blob = StringIO.new(io.read(total_size).reverse)
      
      @height.times do
        # At the end of each row (thus at the beginning byteswap),
        # 2 bytes contain garbage since rows are aligned
        # to start at 8-complement byte offsets. If they are not discarded this disturbs
        # the RGB cadence of the other values.
        skip = blob.read(row_pad)
        
        row = []
        row_data = blob.read(@width.to_i * 3)
        row_data = StringIO.new(row_data.to_s)
        
        # Read 3x8bit for each pixel
        @width.times do
          # And guess what - here they are reversed too! How awesome is that!
          rgb = (row_data.read(3) || "AAA").unpack("CCC").reverse
          row.push(pack_rgb(*rgb))
        end
        
        # Abd the row itself is reversed too
        @rows.push(row.reverse)
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
    
    def pack_rgb(r,g,b)
      ChunkyPNG::Color.rgb(r.to_i, g.to_i, b.to_i)
    end
    
    def unpack_rgb(rgb)
      [ChunkyPNG::Color.r(rgb), ChunkyPNG::Color.g(rgb), ChunkyPNG::Color.b(rgb)]
    end
  end
  
end