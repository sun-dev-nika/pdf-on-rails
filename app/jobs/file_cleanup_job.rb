class FileCleanupJob < ApplicationJob
  queue_as :default

  # Guests get no history (per the privacy promise on the homepage); registered
  # users keep their ProcessedFile records so "history" (a signup incentive)
  # actually means something.
  RETENTION = 30.minutes

  def perform
    ProcessedFile.where(user_id: nil).where(created_at: ...RETENTION.ago).find_each do |processed_file|
      destroy_with_files(processed_file)
    end

    # Stuck "pending" rows (e.g. someone started Organize's reorder flow and
    # never confirmed it) are cleaned up for everyone, registered or not -
    # only completed history is meant to be kept forever.
    ProcessedFile.where(status: :pending).where(created_at: ...RETENTION.ago).find_each do |processed_file|
      destroy_with_files(processed_file)
    end
  end

  private

  def destroy_with_files(processed_file)
    processed_file.source_file.purge
    processed_file.result_file.purge
    processed_file.destroy
  end
end
