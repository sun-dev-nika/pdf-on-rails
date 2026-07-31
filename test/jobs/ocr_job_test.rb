require "test_helper"

class OcrJobTest < ActiveJob::TestCase
  test "extracts text and marks the ProcessedFile completed" do
    processed_file = ProcessedFile.create!(operation: "ocr", guest_token: "test-guest")
    processed_file.source_file.attach(
      io: File.open(text_pdf_path("Hola Mundo Testing")),
      filename: "scan.pdf",
      content_type: "application/pdf"
    )

    OcrJob.perform_now(processed_file.id)
    processed_file.reload

    assert processed_file.completed?
    assert processed_file.result_file.attached?
    assert_match(/Hola Mundo Testing/i, processed_file.result_file.download)
  end
end
