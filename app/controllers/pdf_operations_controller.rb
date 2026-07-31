require "base64"

class PdfOperationsController < ApplicationController
  include PdfUploadValidation

  MAX_ORGANIZE_PAGES = 200

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
    files = Array(params[:pdfs]).reject(&:blank?)
    validate_pdfs!(files)

    angle = params[:angle].to_i
    raise InvalidUpload, t("pdf_operations.errors.invalid_angle") unless [ 90, 180, 270 ].include?(angle)

    outputs = files.map do |file|
      with_file_context(file) do
        total_pages = HexaPDF::Document.open(file.tempfile.path).pages.count
        pages = params[:pages].presence && PageRangeParser.parse(params[:pages], total_pages: total_pages)
        PdfRotatorService.new(file.tempfile.path, angle: angle, pages: pages).call
      end
    end

    deliver_batch(files, outputs, operation: "rotate", single_filename: "rotated.pdf", zip_filename: "rotated.zip")
  rescue InvalidUpload => e
    redirect_to rotate_path, alert: e.message
  end

  def delete_pages
  end

  def delete_pages_file
    files = Array(params[:pdfs]).reject(&:blank?)
    validate_pdfs!(files)

    outputs = files.map do |file|
      with_file_context(file) do
        total_pages = HexaPDF::Document.open(file.tempfile.path).pages.count
        pages = PageRangeParser.parse(params[:pages], total_pages: total_pages)
        PdfPageDeleterService.new(file.tempfile.path, pages).call
      end
    end

    deliver_batch(files, outputs, operation: "delete_pages", single_filename: "edited.pdf", zip_filename: "editados.zip")
  rescue InvalidUpload => e
    redirect_to delete_pages_path, alert: e.message
  end

  def compress
  end

  def compress_file
    files = Array(params[:pdfs]).reject(&:blank?)
    validate_pdfs!(files)

    quality = params[:quality].presence || "medium"
    outputs = files.map { |file| with_file_context(file) { PdfCompressorService.new(file.tempfile.path, quality: quality).call } }

    deliver_batch(files, outputs, operation: "compress", single_filename: "comprimido.pdf", zip_filename: "comprimidos.zip")
  rescue InvalidUpload => e
    redirect_to compress_path, alert: e.message
  end

  def watermark
  end

  def watermark_file
    files = Array(params[:pdfs]).reject(&:blank?)
    validate_pdfs!(files)

    text = params[:text].to_s.strip
    raise InvalidUpload, t("pdf_operations.errors.no_watermark_text") if text.blank?

    outputs = files.map { |file| with_file_context(file) { PdfWatermarkService.new(file.tempfile.path, text: text).call } }

    deliver_batch(files, outputs, operation: "watermark", single_filename: "marca_de_agua.pdf", zip_filename: "marcas_de_agua.zip")
  rescue InvalidUpload => e
    redirect_to watermark_path, alert: e.message
  end

  def protect
  end

  def protect_file
    files = Array(params[:pdfs]).reject(&:blank?)
    validate_pdfs!(files)

    password = params[:password].to_s
    raise InvalidUpload, t("pdf_operations.errors.no_password") if password.blank?

    outputs = files.map { |file| with_file_context(file) { PdfProtectorService.new(file.tempfile.path, password: password).call } }

    deliver_batch(files, outputs, operation: "protect", single_filename: "protegido.pdf", zip_filename: "protegidos.zip")
  rescue InvalidUpload => e
    redirect_to protect_path, alert: e.message
  end

  def unlock
  end

  def unlock_file
    files = Array(params[:pdfs]).reject(&:blank?)
    validate_pdfs!(files)

    password = params[:password].to_s
    raise InvalidUpload, t("pdf_operations.errors.no_password") if password.blank?

    outputs = files.map { |file| with_file_context(file) { PdfUnlockerService.new(file.tempfile.path, password: password).call } }

    deliver_batch(files, outputs, operation: "unlock", single_filename: "desbloqueado.pdf", zip_filename: "desbloqueados.zip")
  rescue InvalidUpload => e
    redirect_to unlock_path, alert: e.message
  end

  def ocr
  end

  def ocr_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    processed_file = create_processed_file!(file, operation: "ocr")
    OcrJob.perform_later(processed_file.id)
    redirect_to processed_file_path(processed_file)
  rescue InvalidUpload => e
    redirect_to ocr_path, alert: e.message
  end

  def organize
  end

  def organize_file
    file = params[:pdf]
    validate_pdfs!(Array(file))

    total_pages = HexaPDF::Document.open(file.tempfile.path).pages.count
    raise InvalidUpload, t("pdf_operations.errors.too_many_pages", limit: MAX_ORGANIZE_PAGES) if total_pages > MAX_ORGANIZE_PAGES

    processed_file = create_processed_file!(file, operation: "organize")
    thumbnails = PdfToJpgService.new(file.tempfile.path, resolution: 50).call
    @processed_file = processed_file
    @thumbnails = thumbnails.map { |jpg| Base64.strict_encode64(jpg) }
    render :organize_pages
  rescue InvalidUpload => e
    redirect_to organize_path, alert: e.message
  rescue PdfToJpgService::ConversionFailed, HexaPDF::Error
    processed_file&.source_file&.purge
    processed_file&.destroy
    redirect_to organize_path, alert: t("pdf_operations.errors.corrupted")
  end

  def organize_apply
    processed_file = ProcessedFile.find_by!(id: params[:id], operation: "organize", status: "pending")
    unless processed_file.owned_by?(user: current_user, guest_token: current_guest_token)
      return redirect_to(organize_path, alert: t("processed_files.errors.not_found"))
    end

    order = params[:order].to_s.split(",").map(&:to_i)

    Dir.mktmpdir do |dir|
      source_path = File.join(dir, "source.pdf")
      File.binwrite(source_path, processed_file.source_file.download)

      binary = PdfPageReorderService.new(source_path, order).call

      if user_signed_in?
        processed_file.update!(status: :completed)
        processed_file.result_file.attach(io: StringIO.new(binary), filename: "organizado.pdf", content_type: "application/pdf")
      else
        processed_file.source_file.purge
        processed_file.destroy
      end

      send_pdf(binary, "organizado.pdf")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to organize_path, alert: t("processed_files.errors.not_found")
  rescue PdfPageReorderService::InvalidOrder, HexaPDF::Error
    redirect_to organize_path, alert: t("pdf_operations.errors.corrupted")
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

  # Runs a per-file step of a batch operation, translating the same
  # exception types each tool already handles for the single-file case into
  # an InvalidUpload prefixed with the offending file's name - so a batch of
  # 5 files failing on file #3 tells the user which one, instead of a bare
  # generic message. Anything not in this list is a real bug, not a
  # translatable user error, so it's left to propagate normally.
  def with_file_context(file)
    yield
  rescue PageRangeParser::InvalidRange => e
    raise InvalidUpload, "#{file.original_filename}: #{range_error_message(e)}"
  rescue PdfPageDeleterService::AllPagesDeleted
    raise InvalidUpload, "#{file.original_filename}: #{t('pdf_operations.errors.all_pages_deleted')}"
  rescue PdfUnlockerService::WrongPassword
    raise InvalidUpload, "#{file.original_filename}: #{t('pdf_operations.errors.wrong_password')}"
  rescue PdfCompressorService::CompressionFailed, PdfProtectorService::EncryptionFailed, HexaPDF::Error
    raise InvalidUpload, "#{file.original_filename}: #{t('pdf_operations.errors.corrupted')}"
  end

  # Shared "one file in, one or more files out" delivery path used by every
  # batch-capable sync tool: a single input yields a plain PDF download, more
  # than one yields a ZIP - same dual-output shape Split already used before
  # any tool supported multiple files.
  def deliver_batch(files, outputs, operation:, single_filename:, zip_filename:)
    if outputs.size == 1
      record_history!(operation: operation, result_binary: outputs.first, filename: single_filename, original_filename: files.first.original_filename)
      send_pdf(outputs.first, single_filename)
    else
      buffer = build_named_zip(files.zip(outputs))
      record_history!(
        operation: operation, result_binary: buffer, filename: zip_filename,
        original_filename: t("processed_files.index.batch_filename", count: outputs.size), content_type: "application/zip"
      )
      send_data buffer, filename: zip_filename, type: "application/zip", disposition: "attachment"
    end
  end
end
