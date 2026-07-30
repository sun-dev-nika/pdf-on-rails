require "test_helper"

class PdfSplitterServiceTest < ActiveSupport::TestCase
  test "extracts each page group into its own document" do
    source = blank_pdf_path(5)

    outputs = PdfSplitterService.new(source, [ [ 1, 2 ], [ 3, 4, 5 ] ]).call

    assert_equal 2, outputs.size
    assert_equal 2, HexaPDF::Document.new(io: StringIO.new(outputs[0])).pages.count
    assert_equal 3, HexaPDF::Document.new(io: StringIO.new(outputs[1])).pages.count
  end
end
