require "open3"
require "tmpdir"
require "timeout"

class OfficeConverterService
  class ConversionFailed < StandardError; end

  TIMEOUT_SECONDS = 120

  def initialize(path)
    @path = path
  end

  def call
    Dir.mktmpdir do |dir|
      status = run_conversion(dir)
      output_path = Dir.glob(File.join(dir, "*.pdf")).first
      raise ConversionFailed, "conversion failed or timed out" unless status&.success? && output_path

      File.binread(output_path)
    end
  end

  private

  def run_conversion(dir)
    Timeout.timeout(TIMEOUT_SECONDS) do
      _stdout, _stderr, status = Open3.capture3(
        "soffice", "--headless", "--norestore", "--convert-to", "pdf", "--outdir", dir, @path
      )
      status
    end
  rescue Timeout::Error
    nil
  end
end
