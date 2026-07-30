class OcrJob < ApplicationJob
  queue_as :default

  def perform(processed_file_id)
    processed_file = ProcessedFile.find(processed_file_id)
    processed_file.update!(status: :processing)

    Dir.mktmpdir do |dir|
      source_path = File.join(dir, "source.pdf")
      File.binwrite(source_path, processed_file.source_file.download)

      text = OcrService.new(source_path).call

      processed_file.result_file.attach(
        io: StringIO.new(text),
        filename: "#{File.basename(processed_file.original_filename.to_s, ".*")}.txt",
        content_type: "text/plain"
      )
      processed_file.update!(status: :completed)
    end
  rescue => e
    processed_file&.update!(status: :failed, error_message: e.message)
  end
end
