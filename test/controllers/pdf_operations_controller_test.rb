require "test_helper"

class PdfOperationsControllerTest < ActionDispatch::IntegrationTest
  test "signed-in users get a history record after running a sync tool" do
    sign_in users(:one)

    post compress_path, params: { pdfs: [ pdf_upload(2) ], quality: "low" }

    assert_response :success
    processed_file = users(:one).processed_files.order(:created_at).last
    assert_equal "compress", processed_file.operation
    assert processed_file.completed?
    assert processed_file.result_file.attached?
  end

  test "guests do not get a history record" do
    assert_no_difference("ProcessedFile.count") do
      post compress_path, params: { pdfs: [ pdf_upload(2) ], quality: "low" }
    end

    assert_response :success
  end

  BATCH_CASES = {
    rotate_path: { pages: :pdfs, extra: { angle: "90" } },
    delete_pages_path: { pages: :pdfs, extra: { pages: "1" } },
    compress_path: { pages: :pdfs, extra: { quality: "low" } },
    watermark_path: { pages: :pdfs, extra: { text: "CONFIDENTIAL" } },
    protect_path: { pages: :pdfs, extra: { password: "secret123" } },
    unlock_path: { pages: :pdfs, extra: { password: "secret123" }, encrypted: true }
  }.freeze

  BATCH_CASES.each do |path_helper, config|
    test "batch #{path_helper.to_s.sub('_path', '')} returns a ZIP for multiple files" do
      files = if config[:encrypted]
        [ encrypted_pdf_upload("secret123"), encrypted_pdf_upload("secret123") ]
      else
        [ pdf_upload(2), pdf_upload(2) ]
      end

      post send(path_helper), params: { pdfs: files, **config[:extra] }

      assert_response :success
      assert_equal "application/zip", response.media_type
    end
  end

  test "organize flow: guest reorders pages and downloads, staged record is destroyed" do
    post organize_path, params: { pdf: pdf_upload(3) }
    assert_response :success
    assert_equal 3, response.body.scan('data-page="').size

    processed_file = ProcessedFile.where(operation: "organize").last

    patch organize_apply_path(processed_file), params: { order: "3,1,2" }

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_not ProcessedFile.exists?(processed_file.id)
  end

  test "organize flow: signed-in user's result is saved to history" do
    sign_in users(:one)

    post organize_path, params: { pdf: pdf_upload(3) }
    processed_file = users(:one).processed_files.where(operation: "organize").last

    patch organize_apply_path(processed_file), params: { order: "3,1,2" }

    assert_response :success
    processed_file.reload
    assert processed_file.completed?
    assert processed_file.result_file.attached?
  end

  test "organize_apply refuses to reorder another user's staged file" do
    sign_in users(:one)
    post organize_path, params: { pdf: pdf_upload(2) }
    processed_file = users(:one).processed_files.where(operation: "organize").last
    sign_out users(:one)

    sign_in users(:two)
    patch organize_apply_path(processed_file), params: { order: "2,1" }

    assert_redirected_to organize_path
  end

  private

  def pdf_upload(pages)
    Rack::Test::UploadedFile.new(blank_pdf_path(pages), "application/pdf")
  end

  def encrypted_pdf_upload(password)
    binary = PdfProtectorService.new(blank_pdf_path(1), password: password).call
    path = Rails.root.join("tmp", "test_pdf_#{SecureRandom.hex(6)}.pdf")
    File.binwrite(path, binary)
    Rack::Test::UploadedFile.new(path.to_s, "application/pdf")
  end
end
