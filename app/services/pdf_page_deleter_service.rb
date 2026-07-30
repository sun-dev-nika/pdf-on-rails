class PdfPageDeleterService
  class AllPagesDeleted < StandardError; end

  # pages: list of 1-indexed page numbers to remove
  def initialize(path, pages)
    @path = path
    @pages = pages
  end

  def call
    doc = HexaPDF::Document.open(@path)
    raise AllPagesDeleted if @pages.uniq.size >= doc.pages.count

    @pages.uniq.sort.reverse_each { |page_number| doc.pages.delete_at(page_number - 1) }
    PdfDocumentWriter.to_binary(doc)
  end
end
