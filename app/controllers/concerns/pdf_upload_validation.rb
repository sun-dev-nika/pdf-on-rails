require "marcel"

module PdfUploadValidation
  extend ActiveSupport::Concern

  MAX_GUEST_SIZE = 20.megabytes
  MAX_USER_SIZE = 50.megabytes

  class InvalidUpload < StandardError; end

  private

  def send_pdf(binary, filename)
    send_data binary, filename: filename, type: "application/pdf", disposition: "attachment"
  end

  def send_zip(binaries, filename, extension:)
    buffer = Zip::OutputStream.write_buffer do |stream|
      binaries.each_with_index do |binary, index|
        stream.put_next_entry("parte_#{index + 1}.#{extension}")
        stream.write(binary)
      end
    end
    send_data buffer.string, filename: filename, type: "application/zip", disposition: "attachment"
  end

  def validate_uploads!(files, content_type:, wrong_type_key:, minimum: 1)
    raise InvalidUpload, t("pdf_operations.errors.no_file") if files.empty?
    raise InvalidUpload, t("pdf_operations.errors.need_multiple") if files.size < minimum

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
end
