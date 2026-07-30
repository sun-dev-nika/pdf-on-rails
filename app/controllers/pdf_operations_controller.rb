require "marcel"

class PdfOperationsController < ApplicationController
  MAX_GUEST_SIZE = 20.megabytes
  MAX_USER_SIZE = 50.megabytes

  class InvalidUpload < StandardError; end

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
      send_zip(outputs, "split.zip")
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

  private

  def send_pdf(binary, filename)
    send_data binary, filename: filename, type: "application/pdf", disposition: "attachment"
  end

  def send_zip(binaries, filename)
    buffer = Zip::OutputStream.write_buffer do |stream|
      binaries.each_with_index do |binary, index|
        stream.put_next_entry("parte_#{index + 1}.pdf")
        stream.write(binary)
      end
    end
    send_data buffer.string, filename: filename, type: "application/zip", disposition: "attachment"
  end

  def validate_pdfs!(files, minimum: 1)
    raise InvalidUpload, t("pdf_operations.errors.no_file") if files.empty?
    raise InvalidUpload, t("pdf_operations.errors.need_multiple") if files.size < minimum

    files.each do |file|
      if file.size > max_upload_size
        raise InvalidUpload, t("pdf_operations.errors.too_large", limit: max_upload_size / 1.megabyte)
      end
      unless pdf?(file)
        raise InvalidUpload, t("pdf_operations.errors.not_pdf", filename: file.original_filename)
      end
    end
  end

  def pdf?(file)
    Marcel::MimeType.for(file.tempfile, name: file.original_filename) == "application/pdf"
  end

  def max_upload_size
    current_user ? MAX_USER_SIZE : MAX_GUEST_SIZE
  end

  def range_error_message(error)
    t("pdf_operations.errors.range.#{error.reason}", **error.params)
  end
end
