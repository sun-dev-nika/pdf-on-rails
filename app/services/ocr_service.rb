require "tmpdir"
require "rtesseract"

class OcrService
  def initialize(path, language: "spa+eng")
    @path = path
    @language = language
  end

  def call
    Dir.mktmpdir do |dir|
      images = PdfToJpgService.new(@path, resolution: 300).call
      images.each_with_index.map do |image, index|
        image_path = File.join(dir, "page_#{index + 1}.jpg")
        File.binwrite(image_path, image)
        RTesseract.new(image_path, lang: @language).to_s
      end.join("\n\n")
    end
  end
end
