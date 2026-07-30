require "test_helper"

class PdfWatermarkServiceTest < ActiveSupport::TestCase
  test "adds an overlay to every page without changing the page count" do
    source = blank_pdf_path(3)

    binary = PdfWatermarkService.new(source, text: "CONFIDENTIAL").call
    doc = HexaPDF::Document.new(io: StringIO.new(binary))

    assert_equal 3, doc.pages.count
  end
end
