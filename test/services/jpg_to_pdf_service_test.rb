require "test_helper"

class JpgToPdfServiceTest < ActiveSupport::TestCase
  test "creates one page per image" do
    jpgs = [ sample_jpg_path, sample_jpg_path ]

    binary = JpgToPdfService.new(jpgs).call
    doc = HexaPDF::Document.new(io: StringIO.new(binary))

    assert_equal 2, doc.pages.count
  end
end
