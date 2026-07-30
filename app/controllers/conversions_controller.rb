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

  def office_to_pdf
  end

  def office_to_pdf_convert
    file = params[:file]
    validate_office_file!(file)

    processed_file = create_processed_file!(file, operation: "office_to_pdf")
    OfficeConversionJob.perform_later(processed_file.id)
    redirect_to processed_file_path(processed_file)
  rescue InvalidUpload => e
    redirect_to office_to_pdf_path, alert: e.message
  end

  private

  OFFICE_EXTENSIONS = %w[.doc .docx .xls .xlsx .ppt .pptx .odt .ods .odp .rtf].freeze

  def validate_office_file!(file)
    raise InvalidUpload, t("pdf_operations.errors.no_file") if file.blank?
    raise InvalidUpload, t("pdf_operations.errors.too_large", limit: max_upload_size / 1.megabyte) if file.size > max_upload_size

    extension = File.extname(file.original_filename.to_s).downcase
    unless OFFICE_EXTENSIONS.include?(extension)
      raise InvalidUpload, t("conversions.errors.not_office", filename: file.original_filename)
    end
  end
end
