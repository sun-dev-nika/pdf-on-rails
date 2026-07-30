require "test_helper"

class FileCleanupJobTest < ActiveJob::TestCase
  test "deletes old guest files but keeps recent ones and user files" do
    old_guest = ProcessedFile.create!(operation: "ocr", guest_token: "g1", created_at: 1.hour.ago)
    recent_guest = ProcessedFile.create!(operation: "ocr", guest_token: "g2", created_at: 1.minute.ago)
    old_user_file = ProcessedFile.create!(operation: "ocr", user: users(:one), created_at: 1.hour.ago)

    FileCleanupJob.perform_now

    assert_not ProcessedFile.exists?(old_guest.id)
    assert ProcessedFile.exists?(recent_guest.id)
    assert ProcessedFile.exists?(old_user_file.id)
  end
end
