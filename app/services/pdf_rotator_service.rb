class PdfRotatorService
  # pages: nil/empty rotates every page, otherwise a list of 1-indexed page numbers
  def initialize(path, angle:, pages: nil)
    @path = path
    @angle = angle
    @pages = pages
  end

  def call
    doc = HexaPDF::Document.open(@path)
    target_pages = @pages.presence || (1..doc.pages.count).to_a

    target_pages.each do |page_number|
      page = doc.pages[page_number - 1]
      next unless page

      page[:Rotate] = ((page[:Rotate] || 0) + @angle) % 360
    end

    PdfDocumentWriter.to_binary(doc)
  end
end
