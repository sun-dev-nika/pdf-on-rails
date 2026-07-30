module PdfDocumentWriter
  module_function

  def to_binary(doc)
    io = StringIO.new
    doc.write(io, optimize: true)
    io.string
  end
end
