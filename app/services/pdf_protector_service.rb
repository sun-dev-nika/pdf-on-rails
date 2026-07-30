class PdfProtectorService
  # AES-256 (key_length: 256) uses PDF revision 6, which sidesteps a hexapdf edge
  # case around revision <= 4's trailer-ID check that intermittently rejects the
  # correct password right after encrypting. We still verify the round-trip and
  # retry a couple of times as a safety net.
  MAX_ATTEMPTS = 3

  class EncryptionFailed < StandardError; end

  def initialize(path, password:)
    @path = path
    @password = password
  end

  def call
    MAX_ATTEMPTS.times do
      binary = encrypt
      return binary if opens_with_password?(binary)
    end

    raise EncryptionFailed
  end

  private

  def encrypt
    doc = HexaPDF::Document.open(@path)
    doc.encrypt(owner_password: @password, user_password: @password, algorithm: :aes, key_length: 256)
    PdfDocumentWriter.to_binary(doc)
  end

  def opens_with_password?(binary)
    HexaPDF::Document.new(io: StringIO.new(binary), decryption_opts: { password: @password }).pages.count
    true
  rescue HexaPDF::EncryptionError
    false
  end
end
