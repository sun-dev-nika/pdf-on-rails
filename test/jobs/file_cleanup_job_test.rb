require "test_helper"

class FileCleanupJobTest < ActiveJob::TestCase
  test "deletes old guest files but keeps recent ones and completed user history" do
    old_guest = ProcessedFile.create!(operation: "ocr", guest_token: "g1", status: :completed, created_at: 1.hour.ago)
    recent_guest = ProcessedFile.create!(operation: "ocr", guest_token: "g2", status: :completed, created_at: 1.minute.ago)
    old_completed_user_file = ProcessedFile.create!(operation: "ocr", user: users(:one), status: :completed, created_at: 1.hour.ago)

    FileCleanupJob.perform_now

    assert_not ProcessedFile.exists?(old_guest.id)
    assert ProcessedFile.exists?(recent_guest.id)
    assert ProcessedFile.exists?(old_completed_user_file.id)
  end

  test "deletes stuck pending files regardless of owner" do
    old_pending_guest = ProcessedFile.create!(operation: "organize", guest_token: "g3", status: :pending, created_at: 1.hour.ago)
    old_pending_user_file = ProcessedFile.create!(operation: "organize", user: users(:one), status: :pending, created_at: 1.hour.ago)
    recent_pending_user_file = ProcessedFile.create!(operation: "organize", user: users(:two), status: :pending, created_at: 1.minute.ago)

    FileCleanupJob.perform_now

    assert_not ProcessedFile.exists?(old_pending_guest.id)
    assert_not ProcessedFile.exists?(old_pending_user_file.id)
    assert ProcessedFile.exists?(recent_pending_user_file.id)
  end
end
