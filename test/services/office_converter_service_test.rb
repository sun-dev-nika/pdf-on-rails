require "test_helper"

class OfficeConverterServiceTest < ActiveSupport::TestCase
  test "converts a document to a valid PDF" do
    source = sample_text_document_path

    binary = OfficeConverterService.new(source).call
    doc = HexaPDF::Document.new(io: StringIO.new(binary))

    assert_equal 1, doc.pages.count
  end
end
