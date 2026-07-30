class PdfWatermarkService
  def initialize(path, text:)
    @path = path
    @text = text
  end

  def call
    doc = HexaPDF::Document.open(@path)
    doc.pages.each { |page| stamp(page) }
    PdfDocumentWriter.to_binary(doc)
  end

  private

  def stamp(page)
    canvas = page.canvas(type: :overlay)
    width = page.box.width
    height = page.box.height

    canvas.save_graphics_state do
      canvas.opacity(fill_alpha: 0.25)
      canvas.fill_color(128, 128, 128)
      canvas.font("Helvetica", size: 48)
      canvas.translate(width / 2.0, height / 2.0)
      canvas.rotate(45)
      canvas.text(@text, at: [ -(@text.length * 12), 0 ])
    end
  end
end
