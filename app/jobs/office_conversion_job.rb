class OfficeConversionJob < ApplicationJob
  queue_as :default

  def perform(processed_file_id)
    processed_file = ProcessedFile.find(processed_file_id)
    processed_file.update!(status: :processing)

    Dir.mktmpdir do |dir|
      original_name = processed_file.original_filename.to_s
      extension = File.extname(original_name)
      extension = ".docx" if extension.blank?
      source_path = File.join(dir, "source#{extension}")
      File.binwrite(source_path, processed_file.source_file.download)

      binary = OfficeConverterService.new(source_path).call

      processed_file.result_file.attach(
        io: StringIO.new(binary),
        filename: "#{File.basename(original_name, ".*")}.pdf",
        content_type: "application/pdf"
      )
      processed_file.update!(status: :completed)
    end
  rescue => e
    processed_file&.update!(status: :failed, error_message: e.message)
  end
end
