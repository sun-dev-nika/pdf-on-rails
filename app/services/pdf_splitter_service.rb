class PdfSplitterService
  # page_groups: Array<Array<Integer>> - one entry per output file, each a list of 1-indexed page numbers
  def initialize(path, page_groups)
    @path = path
    @page_groups = page_groups
  end

  def call
    source = HexaPDF::Document.open(@path)
    @page_groups.map do |pages|
      target = HexaPDF::Document.new
      pages.each { |page_number| target.pages << target.import(source.pages[page_number - 1]) }
      PdfDocumentWriter.to_binary(target)
    end
  end
end
