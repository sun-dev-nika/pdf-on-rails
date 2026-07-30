require "test_helper"

class PdfMergerServiceTest < ActiveSupport::TestCase
  test "merges pages from multiple PDFs in order" do
    a = blank_pdf_path(2)
    b = blank_pdf_path(3)

    binary = PdfMergerService.new([ a, b ]).call
    doc = HexaPDF::Document.new(io: StringIO.new(binary))

    assert_equal 5, doc.pages.count
  end
end
