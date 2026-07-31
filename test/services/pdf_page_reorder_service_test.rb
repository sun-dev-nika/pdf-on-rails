require "test_helper"

class PdfPageReorderServiceTest < ActiveSupport::TestCase
  test "reorders pages according to the given sequence" do
    path = distinguishable_pages_pdf_path([ 100, 200, 300 ])

    binary = PdfPageReorderService.new(path, [ 3, 1, 2 ]).call
    result = HexaPDF::Document.new(io: StringIO.new(binary))

    widths = result.pages.map { |page| page.box(:media).width }
    assert_equal [ 300, 100, 200 ], widths
  end

  test "raises when the order isn't a full permutation of the document's pages" do
    path = distinguishable_pages_pdf_path([ 100, 200 ])

    assert_raises(PdfPageReorderService::InvalidOrder) do
      PdfPageReorderService.new(path, [ 1, 1 ]).call
    end
  end

  private

  def distinguishable_pages_pdf_path(widths)
    path = Rails.root.join("tmp", "test_pdf_#{SecureRandom.hex(6)}.pdf")
    doc = HexaPDF::Document.new
    widths.each { |width| doc.pages.add([ 0, 0, width, 200 ]) }
    doc.write(path.to_s, optimize: true)
    path.to_s
  end
end
