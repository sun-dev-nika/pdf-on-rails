require "test_helper"

class PdfCompressorServiceTest < ActiveSupport::TestCase
  test "produces a valid, readable PDF" do
    source = blank_pdf_path(2)

    binary = PdfCompressorService.new(source, quality: "low").call
    doc = HexaPDF::Document.new(io: StringIO.new(binary))

    assert_equal 2, doc.pages.count
  end
end
