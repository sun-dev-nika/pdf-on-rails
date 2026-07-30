require "test_helper"

class PdfRotatorServiceTest < ActiveSupport::TestCase
  test "rotates all pages when no specific pages are given" do
    source = blank_pdf_path(2)

    binary = PdfRotatorService.new(source, angle: 90).call
    doc = HexaPDF::Document.new(io: StringIO.new(binary))

    assert doc.pages.all? { |page| page[:Rotate] == 90 }
  end

  test "rotates only the requested pages" do
    source = blank_pdf_path(3)

    binary = PdfRotatorService.new(source, angle: 180, pages: [ 2 ]).call
    doc = HexaPDF::Document.new(io: StringIO.new(binary))

    assert_equal 0, (doc.pages[0][:Rotate] || 0)
    assert_equal 180, doc.pages[1][:Rotate]
    assert_equal 0, (doc.pages[2][:Rotate] || 0)
  end
end
