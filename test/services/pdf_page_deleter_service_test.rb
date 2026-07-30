require "test_helper"

class PdfPageDeleterServiceTest < ActiveSupport::TestCase
  test "removes the requested pages" do
    source = blank_pdf_path(3)

    binary = PdfPageDeleterService.new(source, [ 2 ]).call
    doc = HexaPDF::Document.new(io: StringIO.new(binary))

    assert_equal 2, doc.pages.count
  end

  test "raises when every page would be deleted" do
    source = blank_pdf_path(2)

    assert_raises(PdfPageDeleterService::AllPagesDeleted) do
      PdfPageDeleterService.new(source, [ 1, 2 ]).call
    end
  end
end
