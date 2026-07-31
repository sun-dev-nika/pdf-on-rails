require "marcel"

module PdfUploadValidation
  extend ActiveSupport::Concern

  MAX_GUEST_SIZE = 20.megabytes
  MAX_USER_SIZE = 50.megabytes
  MAX_FILES = 20

  class InvalidUpload < StandardError; end

  private

  def send_pdf(binary, filename)
    send_data binary, filename: filename, type: "application/pdf", disposition: "attachment"
  end

  def send_zip(binaries, filename, extension:)
    send_data build_zip(binaries, extension: extension), filename: filename, type: "application/zip", disposition: "attachment"
  end

  def build_zip(binaries, extension:)
    Zip::OutputStream.write_buffer do |stream|
      binaries.each_with_index do |binary, index|
        stream.put_next_entry("parte_#{index + 1}.#{extension}")
        stream.write(binary)
      end
    end.string
  end

  # Like build_zip, but names each entry after the uploaded file it came
  # from (used by batch mode, where "parte_1.pdf" etc. would leave the user
  # unable to tell which output corresponds to which input). The index
  # prefix guards against two uploads sharing a filename colliding.
  def build_named_zip(file_and_binary_pairs)
    Zip::OutputStream.write_buffer do |stream|
      file_and_binary_pairs.each_with_index do |(file, binary), index|
        safe_name = File.basename(file.original_filename.to_s)
        stream.put_next_entry("#{index + 1}_#{safe_name}")
        stream.write(binary)
      end
    end.string
  end

  def validate_uploads!(files, content_type:, wrong_type_key:, minimum: 1)
    raise InvalidUpload, t("pdf_operations.errors.no_file") if files.empty?
    raise InvalidUpload, t("pdf_operations.errors.need_multiple") if files.size < minimum
    raise InvalidUpload, t("pdf_operations.errors.too_many_files", limit: MAX_FILES) if files.size > MAX_FILES

    files.each do |file|
      if file.size > max_upload_size
        raise InvalidUpload, t("pdf_operations.errors.too_large", limit: max_upload_size / 1.megabyte)
      end
      unless Marcel::MimeType.for(file.tempfile, name: file.original_filename) == content_type
        raise InvalidUpload, t(wrong_type_key, filename: file.original_filename)
      end
    end
  end

  def max_upload_size
    current_user ? MAX_USER_SIZE : MAX_GUEST_SIZE
  end

  # Persists the upload as a ProcessedFile for operations that run in a
  # background job (OCR, Office conversion) instead of the same request.
  def create_processed_file!(file, operation:)
    processed_file = ProcessedFile.new(
      operation: operation,
      original_filename: file.original_filename,
      user: current_user,
      guest_token: current_user ? nil : current_guest_token
    )
    processed_file.source_file.attach(
      io: file.tempfile,
      filename: file.original_filename,
      content_type: file.content_type
    )
    processed_file.save!
    processed_file
  end

  # Records a completed synchronous operation to the signed-in user's history
  # (guests get no history, per the privacy promise on the homepage). Never
  # raises - a history-recording bug must never break the actual download.
  def record_history!(operation:, result_binary:, filename:, original_filename: nil, content_type: "application/pdf")
    return unless user_signed_in?

    processed_file = current_user.processed_files.create!(operation: operation, status: :completed, original_filename: original_filename)
    processed_file.result_file.attach(io: StringIO.new(result_binary), filename: filename, content_type: content_type)
  rescue => e
    Rails.logger.error("record_history! failed for operation=#{operation}: #{e.message}")
  end
end
