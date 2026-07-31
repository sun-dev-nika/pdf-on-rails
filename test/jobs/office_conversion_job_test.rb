require "test_helper"

class OfficeConversionJobTest < ActiveJob::TestCase
  test "converts the source file and marks the ProcessedFile completed" do
    processed_file = ProcessedFile.create!(
      operation: "office_to_pdf", guest_token: "test-guest", original_filename: "report.txt"
    )
    processed_file.source_file.attach(
      io: File.open(sample_text_document_path),
      filename: "report.txt",
      content_type: "text/plain"
    )

    OfficeConversionJob.perform_now(processed_file.id)
    processed_file.reload

    assert processed_file.completed?
    assert processed_file.result_file.attached?
    doc = HexaPDF::Document.new(io: StringIO.new(processed_file.result_file.download))
    assert_operator doc.pages.count, :>=, 1
  end
end
