class JpgToPdfService
  def initialize(paths)
    @paths = paths
  end

  def call
    doc = HexaPDF::Document.new
    @paths.each do |path|
      image = doc.images.add(path)
      page = doc.pages.add([ 0, 0, image.width, image.height ])
      page.canvas.image(image, at: [ 0, 0 ], width: image.width, height: image.height)
    end
    PdfDocumentWriter.to_binary(doc)
  end
end
