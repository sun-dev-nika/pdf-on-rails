require "test_helper"

class PdfUnlockerServiceTest < ActiveSupport::TestCase
  # Regression test: hexapdf keeps the security handler set up after decrypting
  # for reading, so writing the document back out re-encrypts it unless the
  # service explicitly clears it. Caught this by actually round-tripping the
  # output through a fresh, password-less open below.
  test "removes the password so the output opens without one" do
    source = blank_pdf_path(2)
    protected_path = write_temp_pdf(PdfProtectorService.new(source, password: "secret123").call)

    unlocked_binary = PdfUnlockerService.new(protected_path, password: "secret123").call
    doc = HexaPDF::Document.new(io: StringIO.new(unlocked_binary))

    assert_equal 2, doc.pages.count
    assert_not doc.encrypted?
  end

  test "raises WrongPassword for an incorrect password" do
    source = blank_pdf_path(2)
    protected_path = write_temp_pdf(PdfProtectorService.new(source, password: "secret123").call)

    assert_raises(PdfUnlockerService::WrongPassword) do
      PdfUnlockerService.new(protected_path, password: "wrong").call
    end
  end

  private

  def write_temp_pdf(binary)
    path = Rails.root.join("tmp", "test_pdf_#{SecureRandom.hex(6)}.pdf").to_s
    File.binwrite(path, binary)
    path
  end
end
