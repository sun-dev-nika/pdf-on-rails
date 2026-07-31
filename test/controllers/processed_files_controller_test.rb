require "test_helper"

class ProcessedFilesControllerTest < ActionDispatch::IntegrationTest
  test "guests are redirected away from history" do
    get history_path
    assert_redirected_to new_user_session_path
  end

  test "signed-in users only see their own history" do
    sign_in users(:one)

    get history_path

    assert_response :success
    assert_match "scanned.pdf", response.body
    assert_no_match "report.docx", response.body
  end
end
