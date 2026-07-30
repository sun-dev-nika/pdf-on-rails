require "test_helper"

class PdfProtectorServiceTest < ActiveSupport::TestCase
  test "encrypts the PDF so it requires the password to open" do
    source = blank_pdf_path(2)

    binary = PdfProtectorService.new(source, password: "secret123").call

    assert_raises(HexaPDF::EncryptionError) do
      HexaPDF::Document.new(io: StringIO.new(binary))
    end

    doc = HexaPDF::Document.new(io: StringIO.new(binary), decryption_opts: { password: "secret123" })
    assert_equal 2, doc.pages.count
  end
end
