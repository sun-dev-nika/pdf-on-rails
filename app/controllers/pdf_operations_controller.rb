class PdfOperationsController < ApplicationController
  include PdfUploadValidation

  def merge
  end

  def merge_files
    files = Array(params[:pdfs]).reject(&:blank?)
    validate_pdfs!(files, minimum: 2)

    binary = PdfMergerService.new(files.map { |file| file.tempfile.path }).call
    send_pdf(binary, "merged.pdf")
  rescue InvalidUpload => e
    redirect_to merge_path, alert: e.message
  rescue HexaPDF::Error
    redirect_to merge_path, alert: t("pdf_operations.errors.corrupted")
  end

  def split
  end

  def split_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    total_pages = HexaPDF::Document.open(file.tempfile.path).pages.count
    ranges = Array(params[:ranges]).reject(&:blank?)
    raise InvalidUpload, t("pdf_operations.errors.no_ranges") if ranges.empty?

    page_groups = ranges.map { |range| PageRangeParser.parse(range, total_pages: total_pages) }
    outputs = PdfSplitterService.new(file.tempfile.path, page_groups).call

    if outputs.size == 1
      send_pdf(outputs.first, "split.pdf")
    else
      send_zip(outputs, "split.zip", extension: "pdf")
    end
  rescue InvalidUpload => e
    redirect_to split_path, alert: e.message
  rescue PageRangeParser::InvalidRange => e
    redirect_to split_path, alert: range_error_message(e)
  rescue HexaPDF::Error
    redirect_to split_path, alert: t("pdf_operations.errors.corrupted")
  end

  def rotate
  end

  def rotate_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    angle = params[:angle].to_i
    raise InvalidUpload, t("pdf_operations.errors.invalid_angle") unless [ 90, 180, 270 ].include?(angle)

    total_pages = HexaPDF::Document.open(file.tempfile.path).pages.count
    pages = params[:pages].presence && PageRangeParser.parse(params[:pages], total_pages: total_pages)

    binary = PdfRotatorService.new(file.tempfile.path, angle: angle, pages: pages).call
    send_pdf(binary, "rotated.pdf")
  rescue InvalidUpload => e
    redirect_to rotate_path, alert: e.message
  rescue PageRangeParser::InvalidRange => e
    redirect_to rotate_path, alert: range_error_message(e)
  rescue HexaPDF::Error
    redirect_to rotate_path, alert: t("pdf_operations.errors.corrupted")
  end

  def delete_pages
  end

  def delete_pages_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    total_pages = HexaPDF::Document.open(file.tempfile.path).pages.count
    pages = PageRangeParser.parse(params[:pages], total_pages: total_pages)

    binary = PdfPageDeleterService.new(file.tempfile.path, pages).call
    send_pdf(binary, "edited.pdf")
  rescue InvalidUpload => e
    redirect_to delete_pages_path, alert: e.message
  rescue PageRangeParser::InvalidRange => e
    redirect_to delete_pages_path, alert: range_error_message(e)
  rescue PdfPageDeleterService::AllPagesDeleted
    redirect_to delete_pages_path, alert: t("pdf_operations.errors.all_pages_deleted")
  rescue HexaPDF::Error
    redirect_to delete_pages_path, alert: t("pdf_operations.errors.corrupted")
  end

  def compress
  end

  def compress_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    binary = PdfCompressorService.new(file.tempfile.path, quality: params[:quality].presence || "medium").call
    send_pdf(binary, "comprimido.pdf")
  rescue InvalidUpload => e
    redirect_to compress_path, alert: e.message
  rescue PdfCompressorService::CompressionFailed
    redirect_to compress_path, alert: t("pdf_operations.errors.corrupted")
  end

  def watermark
  end

  def watermark_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    text = params[:text].to_s.strip
    raise InvalidUpload, t("pdf_operations.errors.no_watermark_text") if text.blank?

    binary = PdfWatermarkService.new(file.tempfile.path, text: text).call
    send_pdf(binary, "marca_de_agua.pdf")
  rescue InvalidUpload => e
    redirect_to watermark_path, alert: e.message
  rescue HexaPDF::Error
    redirect_to watermark_path, alert: t("pdf_operations.errors.corrupted")
  end

  def protect
  end

  def protect_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    password = params[:password].to_s
    raise InvalidUpload, t("pdf_operations.errors.no_password") if password.blank?

    binary = PdfProtectorService.new(file.tempfile.path, password: password).call
    send_pdf(binary, "protegido.pdf")
  rescue InvalidUpload => e
    redirect_to protect_path, alert: e.message
  rescue PdfProtectorService::EncryptionFailed, HexaPDF::Error
    redirect_to protect_path, alert: t("pdf_operations.errors.corrupted")
  end

  def unlock
  end

  def unlock_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    password = params[:password].to_s
    raise InvalidUpload, t("pdf_operations.errors.no_password") if password.blank?

    binary = PdfUnlockerService.new(file.tempfile.path, password: password).call
    send_pdf(binary, "desbloqueado.pdf")
  rescue InvalidUpload => e
    redirect_to unlock_path, alert: e.message
  rescue PdfUnlockerService::WrongPassword
    redirect_to unlock_path, alert: t("pdf_operations.errors.wrong_password")
  rescue HexaPDF::Error
    redirect_to unlock_path, alert: t("pdf_operations.errors.corrupted")
  end

  private

  def validate_pdfs!(files, minimum: 1)
    validate_uploads!(
      files,
      content_type: "application/pdf",
      wrong_type_key: "pdf_operations.errors.not_pdf",
      minimum: minimum
    )
  end

  def range_error_message(error)
    t("pdf_operations.errors.range.#{error.reason}", **error.params)
  end
end
