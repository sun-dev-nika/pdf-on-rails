class PdfMergerService
  def initialize(paths)
    @paths = paths
  end

  def call
    target = HexaPDF::Document.new
    @paths.each do |path|
      source = HexaPDF::Document.open(path)
      source.pages.each { |page| target.pages << target.import(page) }
    end
    PdfDocumentWriter.to_binary(target)
  end
end
