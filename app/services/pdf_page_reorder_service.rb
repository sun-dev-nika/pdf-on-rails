class PdfPageReorderService
  class InvalidOrder < StandardError; end

  # order: 1-indexed page numbers describing the new sequence, e.g. [3, 1, 2]
  # on a 3-page document moves the current third page to the front. Must be
  # a permutation of every page in the document - no dropping or duplicating.
  def initialize(path, order)
    @path = path
    @order = order
  end

  def call
    doc = HexaPDF::Document.open(@path)
    total = doc.pages.count
    raise InvalidOrder unless @order.size == total && @order.sort == (1..total).to_a

    pages_in_new_order = @order.map { |page_number| doc.pages[page_number - 1] }
    pages_in_new_order.each_with_index { |page, target_index| doc.pages.move(page, target_index) }

    PdfDocumentWriter.to_binary(doc)
  end
end
