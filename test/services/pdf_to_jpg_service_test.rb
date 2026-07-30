require "test_helper"

class PdfToJpgServiceTest < ActiveSupport::TestCase
  test "produces one JPEG per page" do
    source = blank_pdf_path(2)

    images = PdfToJpgService.new(source).call

    assert_equal 2, images.size
    images.each { |image| assert image.start_with?("\xFF\xD8".b) }
  end
end
