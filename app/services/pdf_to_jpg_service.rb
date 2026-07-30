require "open3"
require "tmpdir"

class PdfToJpgService
  class ConversionFailed < StandardError; end

  def initialize(path, resolution: 150)
    @path = path
    @resolution = resolution
  end

  def call
    Dir.mktmpdir do |dir|
      output_pattern = File.join(dir, "page_%03d.jpg")
      _stdout, stderr, status = Open3.capture3(
        "gs", "-dNOPAUSE", "-dBATCH", "-dQUIET", "-sDEVICE=jpeg",
        "-r#{@resolution}", "-o", output_pattern, @path
      )
      raise ConversionFailed, stderr unless status.success?

      pages = Dir.glob(File.join(dir, "page_*.jpg")).sort
      raise ConversionFailed, "no pages produced" if pages.empty?

      pages.map { |page| File.binread(page) }
    end
  end
end
