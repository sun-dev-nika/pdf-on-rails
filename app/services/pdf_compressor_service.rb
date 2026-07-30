require "open3"
require "tmpdir"

class PdfCompressorService
  class CompressionFailed < StandardError; end

  QUALITY_PRESETS = { "low" => "/screen", "medium" => "/ebook", "high" => "/printer" }.freeze

  def initialize(path, quality: "medium")
    @path = path
    @preset = QUALITY_PRESETS.fetch(quality, "/ebook")
  end

  def call
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, "compressed.pdf")
      _stdout, stderr, status = Open3.capture3(
        "gs", "-sDEVICE=pdfwrite", "-dCompatibilityLevel=1.4",
        "-dPDFSETTINGS=#{@preset}", "-dNOPAUSE", "-dBATCH", "-dQUIET",
        "-sOutputFile=#{output_path}", @path
      )
      raise CompressionFailed, stderr unless status.success? && File.exist?(output_path)

      File.binread(output_path)
    end
  end
end
