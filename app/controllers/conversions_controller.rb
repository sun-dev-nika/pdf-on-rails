class ConversionsController < ApplicationController
  include PdfUploadValidation

  def jpg_to_pdf
  end

  def jpg_to_pdf_convert
    files = Array(params[:jpgs]).reject(&:blank?)
    validate_uploads!(files, content_type: "image/jpeg", wrong_type_key: "conversions.errors.not_jpg")

    binary = JpgToPdfService.new(files.map { |file| file.tempfile.path }).call
    send_data binary, filename: "convertido.pdf", type: "application/pdf", disposition: "attachment"
  rescue InvalidUpload => e
    redirect_to jpg_to_pdf_path, alert: e.message
  rescue HexaPDF::Error
    redirect_to jpg_to_pdf_path, alert: t("pdf_operations.errors.corrupted")
  end

  def pdf_to_jpg
  end

  def pdf_to_jpg_convert
    file = params[:pdf]
    validate_uploads!(Array(file), content_type: "application/pdf", wrong_type_key: "pdf_operations.errors.not_pdf")

    images = PdfToJpgService.new(file.tempfile.path).call

    if images.size == 1
      send_data images.first, filename: "convertido.jpg", type: "image/jpeg", disposition: "attachment"
    else
      send_zip(images, "convertido.zip", extension: "jpg")
    end
  rescue InvalidUpload => e
    redirect_to pdf_to_jpg_path, alert: e.message
  rescue PdfToJpgService::ConversionFailed, HexaPDF::Error
    redirect_to pdf_to_jpg_path, alert: t("pdf_operations.errors.corrupted")
  end
end
