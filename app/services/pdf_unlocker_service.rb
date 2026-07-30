class PdfUnlockerService
  class WrongPassword < StandardError; end

  def initialize(path, password:)
    @path = path
    @password = password
  end

  def call
    doc = HexaPDF::Document.open(@path, decryption_opts: { password: @password })
    doc.encrypt(name: nil) # strip the security handler, otherwise write() re-encrypts
    PdfDocumentWriter.to_binary(doc)
  rescue HexaPDF::EncryptionError
    raise WrongPassword
  end
end
