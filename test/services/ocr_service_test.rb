require "test_helper"

class OcrServiceTest < ActiveSupport::TestCase
  test "extracts recognizable text from a rendered PDF" do
    source = text_pdf_path("Hola Mundo Testing")

    text = OcrService.new(source).call

    assert_match(/Hola Mundo Testing/i, text)
  end
end
